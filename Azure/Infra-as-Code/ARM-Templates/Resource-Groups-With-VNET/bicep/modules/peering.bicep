param localVnetName string
param remoteVnetName string
param remoteVnetId string
param allowForwardedTraffic bool
param allowVirtualNetworkAccess bool

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${localVnetName}/to-${remoteVnetName}-peering'
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}
