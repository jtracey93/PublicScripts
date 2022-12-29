@description('The Resource ID of the Azure Resource you wish to check a properties state of.')
param parAzResourceId string

@description('The API Version of the Azure Resource you wish to use to check a properties state.')
param parAzResourceApiVersion string

@description('The property of the resource that you wish to check. This is a property inside the `properties` bag of the resource that is captured from a GET call to the Resource ID.')
param parAzResourcePropertyToCheck string

@description('The value of the property of the resource that you wish to check.')
param parAzResourceDesiredState string

@description('How long in seconds the deployment script should wait between check/polling requestes to check the property, and its state, if not in its desired state. Defaults to `30`')
param parWaitInSecondsBetweenIterations int = 30

@description('How many iterations/loops the deployment script should go through to check the property, and its state, if not in its desired state. After this amount of iterations the deployment script will throw an exception and fail and report back to the deployment. Defaults to `30`')
param parMaxIterations int = 30

@description('Deployment Script Resource Name. Defaults to `ds-az-resource-state-check`')
param parDeploymentScriptName string = 'ds-az-resource-state-check'

@description('Deployment Location/Region for resources. Defaults to same location/region as Resource Group being deployed to.')
param parLocation string = resourceGroup().location

@description('Built-in Role Definition ID to assign to the Deployment Script Managed Identity. Defaults to `acdd72a7-3385-48ef-bd42-f606fba81ae7` (Reader)')
param parDeploymentScriptUamiRbacRoleDefinitionIdToAssign string = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

var varDeploymentScriptUamiRbacAssignmentName = guid(resourceGroup().id)

resource resDeploymentScriptUami 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'uami-${parDeploymentScriptName}'
  location: parLocation
}

resource resExistingRbacRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: parDeploymentScriptUamiRbacRoleDefinitionIdToAssign
  scope: subscription()
}

resource resDeploymentScriptUamiRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: varDeploymentScriptUamiRbacAssignmentName
  properties: {
    principalId: resDeploymentScriptUami.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resExistingRbacRoleDefinition.id
  }
}

resource resDeploymentScriptAzResourceStateCheck 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  dependsOn: [
    resDeploymentScriptUamiRbac
  ]
  name: parDeploymentScriptName
  location: parLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resDeploymentScriptUami.id}': {}
    }
  }
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '8.3.0'
    retentionInterval: 'PT2H'
    scriptContent: loadTextContent('../scripts/Invoke-AzResourceStateCheck.ps1')
    arguments: '-azResourceResourceId \'${parAzResourceId}\' -apiVersion \'${parAzResourceApiVersion}\' -azResourcePropertyToCheck \'${parAzResourcePropertyToCheck}\' -azResourceDesiredState \'${parAzResourceDesiredState}\' -waitInSecondsBetweenIterations \'${parWaitInSecondsBetweenIterations}\' -maxIterations \'${parMaxIterations}\''
    cleanupPreference: 'OnSuccess'
    timeout: 'PT1H'
  }
}
