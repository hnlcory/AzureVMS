#Connect to account
#Connect-AzAccount

$azSubs = Get-AzSubscription

#output path setup
if (-Not (Test-Path 'C:\Temp\')){
    New-Item -Path 'C:\Temp\' -ItemType Directory
    Write-host "Created path 'C:\Temp\'" -f Green
}

$vmDets = @()

#set sub context
foreach ( $azSub in $azSubs ) {
    Write-Host "sub id: " $azSub
    Set-AzContext -SubscriptionId $azSub

    $vms = Get-AzVM
    
    foreach ($vm in $vms) {
        Write-Host "vm is: " $vm
        $vmDet= [ordered]@{
            Name = $vm.Name
            Subscription = $azSub.Name
            ResourceGroup = $vm.ResourceGroupName
        }
        #loop for other tags?


        #PSObject with VM details
        $vmObj = New-Object PSObject -Property $vmDet

        #Add to array
        $vmDets += $vmObj
    }
}



#test csv output statement
$vmDets | Export-csv -path c:\Temp\demo.csv -NoTypeInformation
Write-Host "CSV Write Completed"

