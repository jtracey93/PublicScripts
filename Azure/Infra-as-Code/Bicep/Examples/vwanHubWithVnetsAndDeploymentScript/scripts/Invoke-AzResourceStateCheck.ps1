[CmdletBinding()]
param (
  [string]
  $azResourceResourceId,

  [string]
  $apiVersion = "2022-05-01",

  [string]
  $azResourcePropertyToCheck = "provisioningState",

  [string]
  $azResourceDesiredState = "Provisioned",

  [int]
  $waitInSecondsBetweenIterations = 30,

  [int]
  $maxIterations = 30
)

$totalTimeoutCalculation = $waitInSecondsBetweenIterations * $maxIterations

$azResourcePropertyExistenceCheck = Invoke-AzRestMethod -Method GET -Path "$($azResourceResourceId)?api-version=$($apiVersion)"

if ($azResourcePropertyExistenceCheck.StatusCode -ne "200") {
  $DeploymentScriptOutputs["azResourcePropertyState"] = "Not Found"
  throw "Unable to get Azure Resource - $($azResourceResourceId). Likely it doesn't exist. Status code: $($azResourcePropertyExistenceCheck.StatusCode) Error: $($azResourcePropertyExistenceCheck.Content)"
}

$azResourcePropertyStateResult = "Unknown"
$iterationCount = 0

do {
  $azResourcePropertyStateGet = Invoke-AzRestMethod -Method GET -Path "$($azResourceResourceId)?api-version=$($apiVersion)"
  $azResourcePropertyStateJsonConverted = $azResourcePropertyStateGet.Content | ConvertFrom-Json -Depth 10
  $azResourcePropertyStateResult = $azResourcePropertyStateJsonConverted.properties.$($azResourcePropertyToCheck)

  if ($azResourcePropertyStateResult -ne $azResourceDesiredState) {
    Write-Host "Azure Resource Property ($($azResourcePropertyToCheck)) is not in $($azResourceDesiredState) state. Waiting $($waitInSecondsBetweenIterations) seconds before checking again. Iteration count: $($iterationCount)"
    Start-Sleep -Seconds $waitInSecondsBetweenIterations
    $iterationCount++
  }
} while (
  $azResourcePropertyStateResult -ne $azResourceDesiredState -and $iterationCount -ne $maxIterations
)

if ($azResourcePropertyStateResult -eq $azResourceDesiredState) {
  Write-Host "Azure Resource Property ($($azResourcePropertyToCheck)) is now in $($azResourceDesiredState) state."
  $DeploymentScriptOutputs["azResourcePropertyState"] = "$($azResourceDesiredState)"
}

if ($iterationCount -eq $maxIterations -and $azResourcePropertyStateResult -ne $azResourceDesiredState) {
  $DeploymentScriptOutputs["azResourcePropertyState"] = "Azure Resource Property ($($azResourcePropertyToCheck)) is still not in desired state of $($azResourceDesiredState). Timeout reached of $($totalTimeoutCalculation) seconds."
  throw "Azure Resource Property ($($azResourcePropertyToCheck)) is still not in $($azResourceDesiredState) state after $($totalTimeoutCalculation) seconds."
}
