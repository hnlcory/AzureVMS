#connect to account
Connect-AzAccount

$azSubs = Get-AzSubscription

#output path setup
if (-Not (Test-Path 'C:\Temp\')){
    New-Item -Path 'C:\Temp\' -ItemType Directory
    Write-host "Created path 'C:\Temp\'" -f Green
}

#initialize string builder for CSV
$csvData = "Name,Subscription,ResourceGroup,Tags`n"
$count = $azSubs.Count
$int = 0

foreach ( $azSub in $azSubs ) {
    $int++
    Write-Host "Processing subscription $($azSub.Name) - $int of $count" -ForegroundColor Green
    Set-AzContext -SubscriptionId $azSub.Id
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        $vmName = $vm.Name
        $vmRG = $vm.ResourceGroupName
        $vmSub = $azSub.Name

        #get tags for VM
        $vmTags = (Get-AzResource -ResourceId $vm.Id).Tags

        #add main data and tags to string builder
        $csvData += "$vmName ,$vmSub ,$vmRG"
   
        #loop through all add to string builder
        foreach ($key in $vmTags.Keys) {
            $csvData += "$key=$($vmTags[$key]),"
        }
        $csvData += "`n"
    }   
}
$csvData | Set-Content -Path 'C:\Temp\VMs.csv' 
Write-Host "CSV file exported to C:\Temp\VMs.csv" -ForegroundColor Green