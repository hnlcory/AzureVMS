$data = "John,Doe,42,NewYork"
$dataArray = $data.Split(',')

Write-Output $dataArray

$csvData = $dataArray | ConvertFrom-Csv -Delimiter ";"
$csvData | Export-Csv -Path 'C:\Temp\output.csv' -NoTypeInformation