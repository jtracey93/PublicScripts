param namePrefix string = 'acme'
param region string = 'northeurope'
param defaultTags object = {
    SourceGitHubRepo: 'https://github.com/jtracey93/PublicScripts'
    Service: '2 VNETs With Peering Same Resource Group'
}

var vnet1Name = '${namePrefix}-vnet-001'
var vnet2Name = '${namePrefix}-vnet-002'
var vnet1CIDR = '10.1.0.0/16'
var vnet1Subnet1CIDR = '10.1.0.0/24'
var vnet2CIDR = '10.2.0.0/16'
var vnet2Subnet1CIDR = '10.2.0.0/24'

resource vnet1 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet1Name
  location: region
  tags: defaultTags
  properties: {
    addressSpace: {
        addressPrefixes: [
            vnet1CIDR
        ]
    }
    subnets: [
        {
            name: '${vnet1Name}-subnet-001'
            properties: {
                addressPrefix: vnet1Subnet1CIDR
            }
        }
    ]
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2020-05-01' = {
    name: vnet2Name
    location: region
    tags: defaultTags
    properties: {
      addressSpace: {
          addressPrefixes: [
              vnet2CIDR
          ]
      }
      subnets: [
          {
              name: '${vnet2Name}-subnet-001'
              properties: {
                  addressPrefix: vnet2Subnet1CIDR
                  natGateway: {
                    id: natGateway.id
                  }
              }
          }
      ]
    }
  }

resource vnet1To2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vnet1.name}/vnet-peer-${vnet1Name}-to-${vnet2Name}'
  location: region
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
        id: vnet2.id
    }
  }
}

resource vnet2To1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
    name: '${vnet2.name}/vnet-peer-${vnet2Name}-to-${vnet1Name}'
    location: region
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: false
      allowGatewayTransit: false
      useRemoteGateways: false
      remoteVirtualNetwork: {
          id: vnet1.id
      }
    }
  }

  resource natGateway 'Microsoft.Network/natGateways@2020-06-01' = {
    name: '${namePrefix}-natgw-01'
    location: region
    sku: {
      name: 'Standard'
    }
    tags: defaultTags

  }