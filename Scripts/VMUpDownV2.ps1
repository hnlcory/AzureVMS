# Note: Up/Down time tag must be in 24hr format, Days of week must be first 3 letters ex: Mon 15:30 UTC
# UpTime & DownTime tags are created with times for start and end ex: (05:30,13:30)
# Add vm data to the arrays so we confirm that VMs in array must be started/stoped and for ease of checking on failed start/stops
# Write-Host to Write-Output to pipeline text

$azSubs = Get-AzSubscription
$errList = @() #may not need to be defined immediately
$upLists = @()
$downLists = @()

#debug
$count = $azSubs.Count
$int = 0

foreach ( $azSub in $azSubs ) {
    $int++
    Write-Host "Processing subscription $($azSub.Name) - $int of $count"
    Set-AzContext -SubscriptionId $azSub.Id
    $vms = Get-AzVM #Get-AzVm -ExpandProperties -Select Name,ResourceGroupName,Tags

    foreach ($vm in $vms) {

        #check if tags exist, else ignore
        if ($vm.Tags.ContainsKey("UpTime") -and $vm.Tags.ContainsKey("DownTime") -and $vm.Tags.ContainsKey("DayOfWeek")){
            Write-Host $vm.Name "contains the right tags" -ForegroundColor Green
            $date = (Get-Date).ToUniversalTime()
            $vmTags = (Get-AzResource -ResourceId $vm.Id).Tags
            $vmDOW = $vmTags.DayOfWeek
            $currTime = $date.ToString('HH:mm')
            $upTimeS = ($vmTags.UpTime -split ',')[0]
            $upTimeE = ($vmTags.UpTime -split ',')[1]
            $downTimeS = ($vmTags.DownTime -split ',')[0]
            $downTimeE = ($vmTags.DownTime -split ',')[1]
            Write-Host  $currTime "is the time"

            #if current dayOfWeek matches vmDOW && current time is within the VM upTime window, add VM name, resource group, id to the upList array **CHECK IF VMS ARE ALREADY UP OR DOWN
            if (($vmDOW -split ',' -contains $date.ToString('ddd')) -and (($currTime -ge $upTimeS) -and ($currTime -lt $upTimeE) -and ($currTime -lt $downTimeS -or $currTime -ge $downTimeE)) -and (((Get-AzVM -VMName $vm.Name -Status).powerstate) -ne "VM running")){
                Write-Host $vm.Name "added to upList" -ForegroundColor Green
                $upLists += "$($vm.Name),$($vm.ResourceGroupName),$(($vm.Id -split '/')[2])" #ex: testVm,Intern-Sandbox,49542997-5c0f....
            }

            #if current dayOfWeek matches vmDOW && current time is within the VM downTime window, add VM name, resource group, id to the downList array
            elseif (($vmDOW -split ',' -contains $date.ToString('ddd')) -and (($currTime -ge $downTimeS -or $currTime -lt $downTimeE) -and ($currTime -lt $upTimeS -or $currTime -ge $upTimeE)) -and (((Get-AzVM -VMName $vm.Name -Status).powerstate) -eq "VM running")){
                Write-Host $vm.Name "added to downList" -ForegroundColor Green
                $downLists += "$($vm.Name),$($vm.ResourceGroupName),$(($vm.Id -split '/')[2])"
            }
        }

        #debug
        else {
            Write-Host $vm.Name "does not contain the proper up/down tags" -ForegroundColor Red
        }
    }
}


#if upList has items, startup vms
if ($upLists.Count -ne 0){
    #intial start as job, split for name and resource group
    foreach ($upList in $upLists){
        Write-Host ($upList -split ',')[0] "startup" -ForegroundColor Green
        Set-AzContext -SubscriptionId (Get-AzSubscription -SubscriptionId ($upList -split ',')[2]).Name #set subscription to the subscription of VM first
        Start-AzVM -Name ($upList -split ',')[0] -ResourceGroupName ($upList -split ',')[1] -AsJob
    }
}

#if downList has items, shutdown vms
if ($downLists.Count -ne 0){
     #intial shutdown as job, split for name and resource group
     foreach ($downList in $downLists){
        Write-Host ($downList -split ',')[0] "shutdown" -ForegroundColor Green
        Set-AzContext -SubscriptionId (Get-AzSubscription -SubscriptionId ($downList -split ',')[2]).Name
        Stop-AzVM -Name ($downList -split ',')[0] -ResourceGroupName ($downList -split ',')[1] -Force -AsJob #Force ignores confirmation prompt here
    }
}

#checks may be done in more efficient way via checking job status?  

#currently, jobs not finished before time is done, force a wait period to give last vm chance to shutdown/startup
#Start-Sleep -Seconds 3

#check if up VMs are all up, if not, attempt 2nd time, if not still, add error to array
foreach ($upList in $upLists){
    if (((Get-AzVM -VMName tagTest -Status).powerstate) -ne "VM running"){
        Write-Host ($upList -split ',')[0] "startup failed, retry" -ForegroundColor Red
        Start-AzVM -Name ($upList -split ',')[0] -ResourceGroupName ($upList -split ',')[1] -Force
        #check again, if still failed, add error
        if (((Get-AzVM -VMName ($upList -split ',')[0] -Status).powerstate) -ne ("VM running")){
            $errList += "$(($upList -split ',')[0]) Failed to properly startup`n"
        }
    }
}

#check if down VMs are all down, if not, attempt 2nd time, if not still, add error to array
foreach ($downList in $downLists){
    if ((((Get-AzVM -VMName ($downList -split ',')[0] -Status).powerstate) -ne "VM deallocating") -or (((Get-AzVM -VMName ($downList -split ',')[0] -Status).powerstate) -ne "VM deallocated")){
        Write-Host ($downList -split ',')[0] "shutdown failed, retry" -ForegroundColor Red
        Stop-AzVM -Name ($downList -split ',')[0] -ResourceGroupName ($downList -split ',')[1] -Force
        #check again, if still failed, add error
        if (((Get-AzVM -VMName ($downList -split ',')[0] -Status).powerstate) -ne ("VM deallocated")){
            $errList += "$(($downList -split ',')[0]) Failed to properly shutdown`n"
        }
    }
}

#if errors exist in array, throw error with all of the array info
if ($errList.Count -ne 0){
    throw "Errors occured in script execution: $($errList)"
}

Write-Host "Script Executed"