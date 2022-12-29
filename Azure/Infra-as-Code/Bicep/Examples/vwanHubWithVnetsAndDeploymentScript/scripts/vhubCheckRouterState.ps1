[CmdletBinding()]
param (
  [string]
  $vHubResourceId,

  [string]
  $apiVersion = "2022-01-01"
)

$vHubRouterExistenceCheck = Invoke-AzRestMethod -Method GET -Path "$($vHubResourceId)?api-version=$($apiVersion)" -ErrorAction SilentlyContinue

if ($vHubRouterExistenceCheck.StatusCode -ne "200") {
  $DeploymentScriptOutputs["vHubRouterState"] = "Not Found"
  throw "Unable to get vHub router state. Likely it doesn't exist. Status code: $($vHubRouterExistenceCheck.StatusCode) Error: $($vHubRouterExistenceCheck.Content)"
}

$vHubRouterStateResult = "Unknown"
$iterationCount = 0

do {
  $vHubRouterStateGet = Invoke-AzRestMethod -Method GET -Path "$($vHubResourceId)?api-version=$($apiVersion)"
  $vHubRouterStateJsonConverted = $vHubRouterStateGet.Content | ConvertFrom-Json -Depth 10
  $vHubRouterStateResult = $vHubRouterStateJsonConverted.properties.routingState

  if ($vHubRouterStateResult -ne "Provisioned") {
    Write-Host "Virtual WAN Hub Router is not in Provisioned state. Waiting 30 seconds before checking again. Iteration count: $($iterationCount)"
    Start-Sleep -Seconds 30
    $iterationCount++
  }
} while (
  $vHubRouterStateResult -ne "Provisioned" -and $iterationCount -ne 30
)

if ($vHubRouterStateResult -eq "Provisioned") {
  Write-Host "Virtual WAN Hub Router is now in Provisioned state."
  $DeploymentScriptOutputs["vHubRouterState"] = "Provisioned"
}

if ($iterationCount -eq 30 -and $vHubRouterStateResult -ne "Provisioned") {
  $DeploymentScriptOutputs["vHubRouterState"] = "Still Provisioning. Timeout reached of 15 minutes."
  throw "Virtual WAN Hub Router is still not in Provisioned state after 15 minutes"
}
