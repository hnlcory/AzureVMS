# Note: Up/Down time tag must be in 24hr format, Days of week must be first 3 letters ex: Mon 15:30
# Write-Host to Write-Output to pipeline text

$azSubs = Get-AzSubscription

#remove later
$count = $azSubs.Count
$int = 0


foreach ( $azSub in $azSubs ) {
    $int++
    Write-Host "Processing subscription $($azSub.Name) - $int of $count"
    Set-AzContext -SubscriptionId $azSub.Id
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        #extra
        $vmName = $vm.Name
        $vmRG = $vm.ResourceGroupName
        #$vmSub = $azSub.Name


        #check if tags exist, else ignore
        if ($vm.Tags.ContainsKey("UpTime") -and $vm.Tags.ContainsKey("DownTime") -and $vm.Tags.ContainsKey("DayOfWeek")){

            Write-Host $vmName "continst the right tags" -ForegroundColor Green
            $vmTags = (Get-AzResource -ResourceId $vm.Id).Tags
            $vmDOW = $vmTags.DayOfWeek
            $date = (Get-Date).ToUniversalTime()

            # if the current time is equal to down time && current date matches one of the daysOfWeek, shutdown current vm
            if (($date.ToString('HH:mm') -eq $vmTags.DownTime) -and ($vmDOW -split ',' -contains $date.ToString('ddd'))){ 
                Stop-AzVM -Name $vmName -ResourceGroupName $vmRG
            }
            #else if the current time is equal to up time && current date matches one of the daysOfWeek, startup current vm
            elseif (($date.ToString('HH:mm') -eq $vmTags.UpTime) -and ($vmDOW -split ',' -contains $date.ToString('ddd'))){
                Start-AzVM -Name $vmName -ResourceGroupName $vmRG
            }
        }

        else {
            Write-Host $vmName "does not contain the proper up/down tags" -ForegroundColor Red
        }
       
    }   
}