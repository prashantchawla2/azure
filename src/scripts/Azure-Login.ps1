# Use the Azure Cli to login to an account.
$result = az login

# The result is an array of system.Object (character array), Join it as a string so we have a json string of the result.
$jsonResult = [system.String]::Join("", $result)

# Convert the json result to a list of objects.
$subscriptions = ConvertFrom-Json -InputObject $jsonResult

# Print out all of the subscriptions the user has access to.
foreach ($subscription in $subscriptions)
{
    Write-Host 'name: ' -ForegroundColor Yellow -NoNewline
    Write-Host $subscription.name -ForegroundColor Cyan

    Write-Host 'id: ' -ForegroundColor Yellow -NoNewline
    Write-Host $subscription.id -ForegroundColor Green
    Write-Host
}

# Prompt the user for the subscription of choice.
$subscriptionIdOrName = Read-Host 'Please choose a subscription'

# Configure the cli to the chosen subscription.
az account set --subscription $subscriptionIdOrName

# Search for the subscription
$subscription = $subscriptions | Where-Object { ( $_.id -eq $subscriptionIdOrName ) -or ( $_.name -eq $subscriptionIdOrName ) }

# Return the user information.
return $subscription.user