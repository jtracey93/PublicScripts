targetScope = 'resourceGroup'

@description('Azure region to deploy to')
param region string = 'uksouth'

@description('Azure region naming prefix')
param regionNamePrefix string = 'uks'

@description('CIDR block for VWAN Hub')
param vwanHubCIDR string = '10.0.0.0/23'

@description('VWAN Name')
param vwanName string

@description('Tags to apply to applicable resoruces')
param defaultTags object = {
  'IaC-Source': 'jtracey93/PublicScripts'
}

resource vwanExisting 'Microsoft.Network/virtualWans@2021-02-01' existing = {
  name: vwanName
}

resource vwanHub 'Microsoft.Network/virtualHubs@2021-02-01' = {
  name: 'vwan-hub-${regionNamePrefix}'
  location: region
  tags: defaultTags
  properties: {
    addressPrefix: vwanHubCIDR
    virtualWan: {
      id: vwanExisting.id
    }
  }
}

output outVwanVHubId string = vwanHub.id
