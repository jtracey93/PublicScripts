targetScope = 'resourceGroup'

@description('Azure region to deploy to')
param region string = 'uksouth'

@description('Azure region naming prefix')
param regionNamePrefix string = 'uks'

@description('Tags to apply to applicable resoruces')
param defaultTags object = {
  'IaC-Source': 'jtracey93/PublicScripts'
}

@description('Array of VNET objects, including and array of Subnets. - should be provided from Orchestration template normally.')
param vnets array = []

resource resExistingBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = [for (vnet, i) in vnets: if (vnet.deployBastion == 'yes') {
  name: vnet.subnets.name['AzureBastionSubnet']
}]

resource resBastionPIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'pip-bst-${regionNamePrefix}'
  location: region
  tags: defaultTags
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource resBastion 'Microsoft.Network/bastionHosts@2021-02-01' = [for (vnet, i) in vnets: if (vnet.deployBastion == 'yes') {
  name: 'bst-${regionNamePrefix}-${i}'
  location: region
  tags: defaultTags
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1-${vnet.name}'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name , 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: resBastionPIP.id
          }
        }
      }
    ]
  }
}]

