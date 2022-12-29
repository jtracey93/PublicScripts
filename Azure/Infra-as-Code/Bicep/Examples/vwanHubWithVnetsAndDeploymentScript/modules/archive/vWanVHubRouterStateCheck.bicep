param parVirtualWanVirtualHubResourceId string

param parDeploymentScriptName string = 'ds-vwan-hub-router-check'

param parLocation string = resourceGroup().location

@description('Built-in Role Definition ID to assign to the Deployment Script Managed Identity. Defaults to `4d97b98b-1d4f-4787-a291-c67834d212e7` (Network Contributor)')
param parDeploymentScriptUamiRbacRoleDefinitionIdToAssign string = '4d97b98b-1d4f-4787-a291-c67834d212e7'

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

resource resDeploymentScriptVirtualWanVirtualHubCheck 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
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
    scriptContent: loadTextContent('../scripts/vhubCheckRouterState.ps1')
    arguments: '-vHubResourceId \'${parVirtualWanVirtualHubResourceId}\''
    cleanupPreference: 'OnSuccess'
    timeout: 'PT1H'
  }
}
