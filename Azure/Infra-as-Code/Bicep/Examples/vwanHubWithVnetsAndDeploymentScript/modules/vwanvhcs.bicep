targetScope = 'resourceGroup'

@description('Azure region naming prefix')
param regionNamePrefix string = 'uks'

@description('Array of VNET objects, including and array of Subnets. - should be provided from Orchestration template normally.')
param vnets array = []

resource vwanHubExisting 'Microsoft.Network/virtualHubs@2021-02-01' existing = {
  name: 'vwan-hub-${regionNamePrefix}'
}

@batchSize(1)
resource vwanSpokeVNetConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2021-02-01' = [for (vnet, i) in vnets: {
  parent: vwanHubExisting
  name: 'vnet-${regionNamePrefix}-spoke-conn-${vnet.name}'
  properties: {
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnet.name)
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
}]
