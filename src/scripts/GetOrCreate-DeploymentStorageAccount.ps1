param (
    # True if the azure devops pipeline variable statement should be written to output else false.
    [bool]$azureDevopsPipelineSetVariable = $true
)

# Log to console that the automation prerequisites are being setup.
Write-Progress -Activity "Setting up automation resources" -Status "0% Complete:" -PercentComplete 0;

# The name for the resource group the automation resources are grouped in.
$rgName = 'azure-automation-rg'

# Create the automation resource group.
$result = az group create --location 'northeurope' --name $rgName

# Log to console that the automation prerequisites are being setup.
Write-Progress -Activity "Setting up automation resources" -Status "50% Complete:" -PercentComplete 50;

# Get the storage accounts within the automation resource group.
$storageAccounts = az storage account list --resource-group $rgName | ConvertFrom-Json

# If a storage account exists within the resource group return it.
if ($storageAccounts.Count -gt 0) {
    # Log to console that the automation prerequisites have been fully setup.
    Write-Progress -Activity "Uploading ARM templates" -Status "100% Complete:" -PercentComplete 100;
    Write-Progress -Activity "Setting up automation resources" -Status "Ready" -Completed

    $storageName = $storageAccounts[0].name;
}
# Otherwise create a new storage account and return it.
else {
    $storageName = "deployments" + $(-join ((65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})).toLower()
    $result = az storage account create --name $storageName --resource-group $rgName

    # Log to console that the automation prerequisites have been fully setup.
    Write-Progress -Activity "Uploading ARM templates" -Status "100% Complete:" -PercentComplete 100;
    Write-Progress -Activity "Setting up automation resources" -Status "Ready" -Completed

    $storageName = ($result | ConvertFrom-Json).name
}

if($azureDevopsPipelineSetVariable) 
{
    Write-Output "##vso[task.setvariable variable=storageName]$storageName"
}

return $storageName