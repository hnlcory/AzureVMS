#$path = "C:\Users\CParker\Desktop\Scripts\VMUpDownV2.ps1"
$count = 1

while ($true) {
    Write-Host "running VMUpDownV2 script, runtime = $($count)" -ForegroundColor Green
    & $PSScriptRoot\VMUpDownV2.ps1
    Start-Sleep -Seconds 120
    count++
}