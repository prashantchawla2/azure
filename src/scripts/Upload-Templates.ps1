param (
    # The name of the storage account being uploaded to.
    [string]$storageAccountName,

    # The path to the directory being uploaded to the storage account.
    [string]$directory,

    # The name of the container within the storage account being deployed to.
    [string]$containerName = $( Get-Date -Format "MMddyyyyHHmm" ),

    # True if the azure devops pipeline variable statement should be written to output else false.
    [bool]$azureDevopsPipelineSetVariable = $true
)

# Get the key to the storage account.
Write-Progress -Activity "Uploading ARM templates" -Status "0% Complete:" -PercentComplete 0;
$key = $( az storage account keys list -n $storageAccountName | ConvertFrom-Json )[0].value

# Creates the container.
Write-Progress -Activity "Uploading ARM templates" -Status "25% Complete:" -PercentComplete 25;
$result = az storage container create -n $containerName --account-name $storageAccountName --account-key $key --public-access blob

# Syncs the directory to the storage account container.
Write-Progress -Activity "Uploading ARM templates" -Status "50% Complete:" -PercentComplete 50;
az storage blob sync -c $containerName --account-name $storageAccountName --account-key $key -s $directory | Write-Host -ForegroundColor Yellow
Write-Progress -Activity "Uploading ARM templates" -Status "99% Complete:" -PercentComplete 99;

# Get the storage account info.
$storageAccount = az storage account show --name $storageAccountName | ConvertFrom-Json
Write-Progress -Activity "Uploading ARM templates" -Status "Ready" -Completed

$path = [System.IO.Path]::Combine($storageAccount.primaryEndpoints.blob, $containerName + "/")

if($azureDevopsPipelineSetVariable) 
{
    Write-Output "##vso[task.setvariable variable=containerUri;isOutput=true]$path"
}

# return the endpoint to the container.
return $path