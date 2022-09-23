targetScope = 'resourceGroup'

@description('Azure region to deploy to')
param region string = 'uksouth'

@description('Azure region naming prefix')
param regionNamePrefix string = 'uks'

@description('Tags to apply to applicable resoruces')
param defaultTags object = {
  'IaC-Source': 'jtracey93/PublicScripts'
}

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
    deployBastion: 'yes'
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
    deployBastion: 'no'
  }
  {
    name: 'vnet-uks-3'
    cidr: '10.3.0.0/16'
    subnets: []
    deployBastion: 'no'
  }
]


resource resVNETs 'Microsoft.Network/virtualNetworks@2021-02-01' = [for vnet in vnets: {
  name: vnet.name
  location: region
  tags: defaultTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet.cidr
      ]
    }
    subnets: vnet.subnets
  }
}]
