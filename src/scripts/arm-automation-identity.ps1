$identity = (az identity create --name ARM-AUTOMATION-IDENTITY --resource-group azure-automation-rg | ConvertFrom-Json)
az role assignment create --assignee $identity.principalId --role "Contributor"