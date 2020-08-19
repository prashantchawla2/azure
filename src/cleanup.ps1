param(
    [Parameter(Mandatory = $false)]
    [bool]$force = $false
)

# Sign into an Azure subscription
$user = .\scripts\Azure-Login.ps1

Write-Host 'Retrieving resource groups for subscription'
$result = az group list

# The result is an array of system.Object (character array), Join it as a string so we have a json string of the result.
$jsonResult = [system.String]::Join("", $result)

# Convert the json result to a list of objects.
$resourcegroups = ConvertFrom-Json -InputObject $jsonResult

# Print out all of the resource groups the user has access to.

foreach ($resourcegroup in $resourcegroups)
{
    Write-Host 'name: ' -ForegroundColor Yellow -NoNewline
    Write-Host $resourcegroup.name -ForegroundColor Cyan
}

$resourceGroupName = Read-Host 'Please choose a resource group to delete'

$resourcegroups = $resourcegroups | Where-Object {$_.Name -like $resourceGroupName}
Write-Host 'Deleting the following resource groups' -ForegroundColor Red
foreach ($resourcegroup in $resourcegroups)
{
    Write-Host 'name: ' -ForegroundColor Yellow -NoNewline
    Write-Host $resourcegroup.name -ForegroundColor Cyan
}

ForEach ( $rg in $resourcegroups) { 
    Write-Host "Deleting $($rg.name)" -ForegroundColor Red
    if($force)
    {
        az group delete --name $rg.name --yes
    } else {
        az group delete --name $rg.name
    }
    
    
} 


