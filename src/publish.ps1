param (
    # The environment being deployed to.
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $("dev", "test", "int", "stage", "prod") -contains $_ })]
    [string] $environment = "dev",

    # Resource name prefix
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.Length -gt 0 -And $_.Length -lt 4 })]
    [string] $prefix = "mc",

    # Skip log-in process.
    [Parameter(Mandatory = $false)]
    [ValidateScript( { $($true, $false) -contains $_ })]
    [int] $skipLogin = $false
)

try {
    # Move to the location of this script.
    Push-Location $PsScriptRoot

    if ($environment -eq "dev" -And -Not $skipLogin) {
        # Sign into an Azure subscription
        $user = .\scripts\Azure-Login.ps1
    }

    # Get the storage account to deploy the templates to.
    $storageAccountName = .\scripts\GetOrCreate-DeploymentStorageAccount.ps1 -azureDevopsPipelineSetVariable $false

    # Get the path to the local templates.
    $templatesPath = Resolve-Path .\templates

    # Upload the ARM templates.
    $containerUri = .\scripts\Upload-Templates.ps1 -storageAccountName $storageAccountName -directory $templatesPath -azureDevopsPipelineSetVariable $false

    # Get the templateLink.
    $templateLink = [System.IO.Path]::Combine($containerUri, "azuredeploy.json")

    # Get the parametersLink.
    $parametersFileName = "azuredeploy." + $environment + ".parameters.json"
    $parametersLink = [System.IO.Path]::Combine($containerUri, $parametersFileName)

    # Deploy the main template.
    az deployment create `
        --name 'azuredeploy.json' `
        --location 'westeurope' `
        --template-uri $templateLink `
        --parameters $parametersLink `
        --parameters templateLink=$templateLink --verbose `
        --parameters "{ 'namePrefix': { 'value': '$prefix' }}"
}
finally {
    # Pop to original location.
    Pop-Location
}