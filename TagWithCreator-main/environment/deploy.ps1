$resourceGroupName = "TestVM_group_2"            # <-- REPLACE the variable values with your own values.
$location = "East US"                 # <-- Ensure that the location is a valid Azure location
$storageAccountName = "drcteststoragename"           # <-- Ensure the storage account name is unique
$appServicePlanName = "testServiceName"   # <--
$appInsightsName = "testinsightsname"              # <--
$functionName = "drctestfunctionname"                 # <--

New-AzResourceGroup -Name $resourceGroupName -Location $location -Force -Verbose

$params = @{
    storageAccountName = $storageAccountName.ToLower()
    appServicePlanName = $appServicePlanName
    appInsightsName    = $appInsightsName
    functionName       = $functionName
}

$output = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile .\azuredeploy.json -TemplateParameterObject $params -Verbose

New-AzRoleAssignment -RoleDefinitionName "Reader" -ObjectId $output.Outputs.managedIdentityId.Value -ErrorAction SilentlyContinue -Verbose -Scope (Get-AzContext)[0].Subscription.Id
New-AzRoleAssignment -RoleDefinitionName "Tag Contributor" -ObjectId $output.Outputs.managedIdentityId.Value -ErrorAction SilentlyContinue -Verbose -Scope (Get-AzContext)[0].Subscription.Id

Push-Location
Set-Location ..\functions
Compress-Archive -Path * -DestinationPath ..\environment\functions.zip -Force -Verbose
Pop-Location

$file = (Get-ChildItem .\functions.zip).FullName

Publish-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionName -ArchivePath $file -Verbose -Force

Remove-Item $file -Force
