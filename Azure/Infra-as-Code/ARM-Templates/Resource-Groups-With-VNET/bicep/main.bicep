targetScope = 'subscription'

param namingPrefix string
param region string
param defaultTags object = {
  SourceGitHubRepo: 'https://github.com/jtracey93/PublicScripts'
  Service: 'Resource Group With VNET - Bicep'
}

resource rsgHub 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rsg-${region}-${namingPrefix}-hub'
  location: region
  tags: defaultTags
}

resource rsgSpoke 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rsg-${region}-${namingPrefix}-spoke'
  location: region
  tags: defaultTags
}

module hubVNET 'modules/vnet.bicep' = {
  name: 'hub-vnet-deploy'
  scope: resourceGroup(rsgHub.name)
  params: {
    namingPrefix: namingPrefix
    namingEnvironment: 'hub'
    region: region
    defaultTags: defaultTags
    addressSpace: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'snet-${namingPrefix}-hub-infra'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'snet-${namingPrefix}-hub-dmz'
        properties: {
          addressPrefix: '10.0.250.0/24'
        }
      }
    ]
  }
}

module spokeVNET 'modules/vnet.bicep' = {
  name: 'spoke-vnet-deploy'
  scope: resourceGroup(rsgSpoke.name)
  params: {
    namingPrefix: namingPrefix
    namingEnvironment: 'spoke'
    region: region
    defaultTags: defaultTags
    addressSpace: [
      '10.1.0.0/16'
    ]
    subnets: [
      {
        name: 'snet-${namingPrefix}-spoke-infra'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
      {
        name: 'snet-${namingPrefix}-spoke-dmz'
        properties: {
          addressPrefix: '10.1.250.0/24'
        }
      }
    ]
  }
}

module hubToSpokeVNETPeering 'modules/peering.bicep' = {
  name: 'hub-to-spoke-peering'
  scope: resourceGroup(rsgHub.name)
  params: {
    allowForwardedTraffic: false
    allowVirtualNetworkAccess: true
    localVnetName: hubVNET.outputs.vnetName
    remoteVnetName: spokeVNET.outputs.vnetName
    remoteVnetId: spokeVNET.outputs.vnetID
  }
}

module spokeToHubVNETPeering 'modules/peering.bicep' = {
  name: 'spoke-to-hub-peering'
  scope: resourceGroup(rsgSpoke.name)
  params: {
    allowForwardedTraffic: false
    allowVirtualNetworkAccess: true
    localVnetName: spokeVNET.outputs.vnetName
    remoteVnetName: hubVNET.outputs.vnetName
    remoteVnetId: hubVNET.outputs.vnetID
  }
}