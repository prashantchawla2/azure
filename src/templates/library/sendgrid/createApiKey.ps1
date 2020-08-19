param (
    [string] $username,
    [string] $password,
    [string] $keyName,
    [string] $keyVaultName,
    [string] $secretName
)

$ErrorActionPreference = 'Stop'
$DeploymentScriptOutputs = @{}
$token = ""

# Get token
for ($i = 0; $i -lt 5; $i++) { # 5 retries 
    try {
        $postParams = @{username = $username; password = $password }
        $response = Invoke-WebRequest -Uri https://api.sendgrid.com/v3/public/tokens -Method POST -Body ($postParams | ConvertTo-Json) -ContentType "application/json"
        $token = ($response.Content | ConvertFrom-Json).token
    }
    catch {
        Start-Sleep -s 15
        continue
    }
}
$headers = @{"Authorization" = "token $token" }

# Get Api Keys
$response = Invoke-WebRequest -Uri https://api.sendgrid.com/v3/api_keys -Method GET -Headers $headers
$keys = ($response.Content | ConvertFrom-Json).result

# Delete keys
foreach ($key in $keys) {
    if ($key.name -like "arm-*") {
        $response = Invoke-WebRequest -Uri "https://api.sendgrid.com/v3/api_keys/$($key.api_key_id)" -Method DELETE -Headers $headers
    }
}

# Create send email key
$postParams = @{name = "arm-$keyName"; scopes = @("mail.send") }
$response = Invoke-WebRequest -Uri https://api.sendgrid.com/v3/api_keys -Method POST -Body ($postParams | ConvertTo-Json) -ContentType "application/json" -Headers $headers
$output = ($response.Content | ConvertFrom-Json).api_key

# Add api key to key vault
$secretvalue = ConvertTo-SecureString $output -AsPlainText -Force
$secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secretvalue

# Outputs of script
$DeploymentScriptOutputs['secretUri'] = $secret.Id.replace(":443", "")