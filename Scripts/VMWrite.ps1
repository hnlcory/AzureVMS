# Connect to Azure
Connect-AzAccount

# get user? 
$usrName = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).DisplayName
$vmName = ""


# Get the vm details
$vm = Get-AzVM -Name $vmName


# check if created tag exists


# Create the "CreatedBy" tag with the specified value
$tag = @{ CreatedBy = $usrName }

# Add the tag to the virtual machine -Force?
Set-AzResource -ResourceId $vm.Id -Tag $tag 