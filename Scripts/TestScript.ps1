#Connect to account
#Connect-AzAccount

$azSubs = Get-AzSubscription

#output path setup
if (-Not (Test-Path 'C:\Temp\')){
    New-Item -Path 'C:\Temp\' -ItemType Directory
    Write-host "Created path 'C:\Temp\'" -f Green
}

#for each subscription, get vms name in that sub
foreach ( $azSub in $azSubs ) {
    Write-Host $azSub
    Set-AzContext -SubscriptionId $azSub
    $azVMs = Get-AzVM | Select-Object Name
    Write-Host $azVMs -f Green
}


#test csv output statement
Get-AzResourceGroup | Export-csv -path  c:\Temp\demo.csv

#denied access, future use Get-AzResourceGroup | Export-csv -path  "c:\users\$env:USERNAME\desktop\demo.csv"