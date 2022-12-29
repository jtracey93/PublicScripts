targetScope = 'subscription'

@description('Azure region to deploy to')
param region string = 'uksouth'

@description('Azure region naming prefix')
param regionNamePrefix string = 'uks'

@description('Tags to apply to applicable resoruces')
param defaultTags object = {
  'IaC-Source': 'jtracey93/PublicScripts'
  DemoOf: 'Deployment Scripts Property Checker With VWAN, VWAN Hub & 3 Spokes'
}

@description('CIDR block for VWAN Hub')
param vwanHubCIDR string = '10.0.0.0/23'

@description('Array of VNET objects, including and array of Subnets.')
param vnets array = [
  {
    name: 'vnet-uks-1'
    cidr: '10.1.0.0/16'
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
  }
  {
    name: 'vnet-uks-2'
    cidr: '10.2.0.0/16'
    subnets: [
      {
        name: 'subnet-1'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
      {
        name: 'subnet-2'
        properties: {
          addressPrefix: '10.2.1.0/24'
        }
      }
    ]
  }
  {
    name: 'vnet-uks-3'
    cidr: '10.3.0.0/16'
    subnets: []
  }
]

@description('The API Version of the Azure Resource you wish to use to check a properties state.')
param parAzResourceApiVersion string = '2022-01-01'

@description('The property of the resource that you wish to check. This is a property inside the `properties` bag of the resource that is captured from a GET call to the Resource ID.')
param parAzResourcePropertyToCheck string = 'routingState'

@description('The value of the property of the resource that you wish to check.')
param parAzResourceDesiredState string = 'Provisioned'

@description('How long in seconds the deployment script should wait between check/polling requestes to check the property, and its state, if not in its desired state. Defaults to `30`')
param parWaitInSecondsBetweenIterations int = 30

@description('How many iterations/loops the deployment script should go through to check the property, and its state, if not in its desired state. After this amount of iterations the deployment script will throw an exception and fail and report back to the deployment. Defaults to `30`')
param parMaxIterations int = 30

resource rsg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rsg-${regionNamePrefix}-demo-deployment-scripts-property-checker'
  location: region
  tags: defaultTags
}

module modVNETs './modules/vnet.bicep' = {
  scope: rsg
  name: 'deployVNETs'
  params: {
    region: region
    regionNamePrefix: regionNamePrefix
    defaultTags: defaultTags
    vnets: vnets
  }
}

module modVWAN './modules/vwan.bicep' = {
  scope: rsg
  name: 'deployVWAN'
  params: {
    region: region
    regionNamePrefix: regionNamePrefix
    defaultTags: defaultTags
  }
}

module modVWANHub 'modules/vwanhub.bicep' = {
  scope: rsg
  name: 'deployVWANHub'
  params: {
    region: region
    regionNamePrefix: regionNamePrefix
    defaultTags: defaultTags
    vwanHubCIDR: vwanHubCIDR
    vwanName: modVWAN.outputs.vwanName
  }
}

module modVWANHubRouterCheckerDeploymentScript 'modules/azResourceStateCheck.bicep' = {
  scope: rsg
  name: 'deployVWANHubRouterChecker'
  params: {
    parLocation: region
    parAzResourceId: modVWANHub.outputs.outVwanVHubId
    parAzResourceApiVersion: parAzResourceApiVersion
    parAzResourcePropertyToCheck: parAzResourcePropertyToCheck
    parAzResourceDesiredState: parAzResourceDesiredState
    parMaxIterations: parMaxIterations
    parWaitInSecondsBetweenIterations: parWaitInSecondsBetweenIterations
  }
}

module modVWanVhubVnetConnections 'modules/vwanvhcs.bicep' = {
  dependsOn: [
    modVWANHubRouterCheckerDeploymentScript
  ]
  scope: rsg
  name: 'deployConnectVnetsToVWANVHub'
  params: {
    vnets: vnets
    regionNamePrefix: regionNamePrefix
  }
}
