# Note: Up/Down time tag must be in 24hr format, Days of week must be first 3 letters ex: Mon 15:30 UTC
# Write-Host to Write-Output to pipeline text

$azSubs = Get-AzSubscription

#remove later, for diag
$count = $azSubs.Count
$int = 0

foreach ( $azSub in $azSubs ) {
    $int++
    Write-Host "Processing subscription $($azSub.Name) - $int of $count"
    Set-AzContext -SubscriptionId $azSub.Id
    $vms = Get-AzVM #Get-AzVm -ExpandProperties -Select Name,ResourceGroupName,Tags

    foreach ($vm in $vms) {
        #$vmRG = $vm.ResourceGroupName
        #$vmSub = $azSub.Name

        #check if tags exist, else ignore
        if ($vm.Tags.ContainsKey("UpTime") -and $vm.Tags.ContainsKey("DownTime") -and $vm.Tags.ContainsKey("DayOfWeek")){
            Write-Host $vm.Name "contains the right tags" -ForegroundColor Green
            $vmTags = (Get-AzResource -ResourceId $vm.Id).Tags #Get-AzResource -ResourceId $vm.Id -0DataQuery "properties/tags"
            $vmDOW = $vmTags.DayOfWeek
            $date = (Get-Date).ToUniversalTime()
            $currTime = $date.ToString('HH:mm')
            $upTimeS = ($vmTags.UpTime -split ',')[0]
            $upTimeE = ($vmTags.UpTime -split ',')[1]
            $downTimeS = ($vmTags.DownTime -split ',')[0]
            $downTimeE = ($vmTags.DownTime -split ',')[1]

            
           #if the current time is in up time && current time isnt in range of down time && current date matches one of the daysOfWeek, startup current vm
            if (($vmDOW -split ',' -contains $date.ToString('ddd')) -and (($currTime -ge $upTimeS) -and ($currTime -lt $upTimeE) -and ($currTime -lt $downTimeS -or $currTime -ge $downTimeE))){
                Write-Host $vm.Name "startup" -ForegroundColor Green
                Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -AsJob
            }

            #elseif the current time is in down time && current time isnt in range of up time && current date matches one of the daysOfWeek, shutdown current vm
            elseif (($vmDOW -split ',' -contains $date.ToString('ddd')) -and (($currTime -ge $downTimeS -or $currTime -lt $downTimeE) -and ($currTime -lt $upTimeS -or $currTime -ge $upTimeE))){
                Write-Host $vm.Name "shutdown" -ForegroundColor Green 
                Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -AsJob -Force
            }
        }

        #remove later
        else {
            Write-Host $vm.Name "does not contain the proper up/down tags" -ForegroundColor Red
        }       
    }   
}