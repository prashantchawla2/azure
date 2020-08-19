[string] $ContextVariableName = "mc-az-context"

<#
    .Synopsis
    Gets the Azure context used by other cmdlets in this module.

    .Description
    The Get-MarelConnectAzContext cmdlet gets the Azure context used by other cmdlets in this module.

#>
function Get-MarelConnectAzContext
{
    [CmdletBinding()]
    param()
    $Context = $PsCmdlet.SessionState.PSVariable.GetValue($ContextVariableName)

    if ($null -eq $Context) 
    {
        Throw "Set-MarelConnectAzContext prior to running this cmdlet."
    }
    return $Context
}
Export-ModuleMember Get-MarelConnectAzContext

<#
    .Synopsis
    Sets the Azure context used by other cmdlets in this module.

    .Description
    The Set-MarelConnectAzContext logs the user into Azure and sets
    the current subscription. This cmdlet must be called prior to calling any other cmdlets in this module.

    .Parameter SubscriptionName
    The subscription that the cmdlets in this module will run against.
#>
function Set-MarelConnectAzContext
{
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string] $SubscriptionName
  )

  Connect-AzureRmAccount -Subscription $SubscriptionName
 
  $Context = @{
    Authenticated = $true
  }

  $PsCmdlet.SessionState.PSVariable.Set($ContextVariableName, $Context)
}
Export-ModuleMember Set-MarelConnectAzContext

<#
    .Synopsis
    Removes all resource groups in a subscription that begin with the specified prefix.

    .Description
    The Remove-AzureFMAllResourceGroups cmdlet Removes all resource groups in a subscription 
    that begin with the specified prefix.

    .Parameter ResourceGroupNamePrefix
    The prefix to filter the resource groups by.

    .Parameter ParallelExecution
    When specified the resource groups are removed in parallel.

#>

function Remove-MarelConnectAllResourceGroups
{
  [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $ResourceGroupNamePrefix,

        [Parameter(Mandatory=$false)]
        [switch] $ParallelExecution
    )
  
  Get-MarelConnectAzContext
  
  $resourceGroups = Get-AzureRmResourceGroup | Where-Object { $_.ResourceGroupName.StartsWith($ResourceGroupNamePrefix)}

  if ($null -eq $resourceGroups)
  {
    Write-Error 'No resource groups starting with that prefix were found in the selected subscription.'
  }

  Write-Warning 'The following resource groups will be permanently deleted. Do you wish to continue? (Y/N)'

  foreach ($resourceGroup in $resourceGroups)
  {
    Write-Host $resourceGroup.ResourceGroupName
  }

  $proceed = Read-Host

  if ($proceed -eq 'N')
  {
    return
  }

  if ($ParallelExecution -eq $false)
  {
    foreach ($resourceGroup in $resourceGroups) 
      {
        Remove-AzureRmResourceGroup -Name $resourceGroup.ResourceGroupName -Force -Verbose
      }
  }
  else 
  {
    workflow Remove-ResourceGroupsWorkflow 
    {
        param (
          [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup[]] $resourceGroups
        )

        foreach -parallel ($resourceGroup in $resourceGroups) 
        {
          Remove-AzureRmResourceGroup -Name $resourceGroup.ResourceGroupName -Force -Verbose
        }
    }

    Remove-ResourceGroupsWorkflow -resourceGroups $resourceGroups
  }
}
Export-ModuleMember Remove-MarelConnectAllResourceGroups

<#
    .Synopsis
    Gets a list of running deployments.

    .Description
    The Get-MarelConnectActiveDeployments cmdlet gets a list of deployments that are running or have failed for the resource groups that
    whose names start with the $Prefix parameter value.

    .Parameter ResourceGroupNamePrefix
    The prefix to filter the resource groups by.

    .Parameter PollingIntervalSecs
    The frequency with which the active deployment list is updated.

#>
function Get-MarelConnectActiveDeployments
{
  [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $ResourceGroupNamePrefix,

        [Parameter(Mandatory=$false)]
        [int] $PollingIntervalSecs = 10
    )

    Get-MarelConnectAzContext
    
    while ($true)
    {
      Get-AzureRmResourceGroup | 
      Where-Object {$_.ResourceGroupName.StartsWith($ResourceGroupNamePrefix)} |  
      Get-AzureRmResourceGroupDeployment | 
      Where-Object {$_.ProvisioningState -ne 'Succeeded'} | 
      Sort-Object -Property Timestamp -Descending |  
      Format-Table -Property Timestamp, ProvisioningState, ResourceGroupName, DeploymentName, CorrelationId

      Start-Sleep -Seconds $PollingIntervalSecs
    }    
}
Export-ModuleMember Get-MarelConnectActiveDeployments