targetScope = 'subscription'

@description('Azure region to deploy to')
param region string = 'uksouth'

@description('Azure region naming prefix')
param regionNamePrefix string = 'uks'

@description('Tags to apply to applicable resoruces')
param defaultTags object = {
  'IaC-Source': 'jtracey93/PublicScripts'
  'DemoOf': 'Bastion With VWAN'
}

@description('Boolean to decide whether a VPN Gateway is deployed to the VWAN Hub')
param deployVPNGateway bool = false

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

resource rsg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rsg-${regionNamePrefix}-demo-vwan-bastion'
  location: region
  tags: defaultTags
}

module modVNETs '../Modules/moduleVNet.bicep' = {
  scope: rsg
  name: 'deployVNETs'
  params: {
    region: region
    regionNamePrefix: regionNamePrefix
    defaultTags: defaultTags
    vnets: vnets
  }
}

module modBastion '../Modules/moduleBastion.bicep' = {
  dependsOn: [
    modVNETs
  ]
  scope: rsg
  name: 'deployBastion'
  params: {
    region: region
    regionNamePrefix: regionNamePrefix
    defaultTags: defaultTags
    vnets: vnets
  }

}

module modVWAN '../Modules/moduleVWAN.bicep' = {
  scope: rsg
  name: 'deployVWAN'
  params: {
    region: region
    regionNamePrefix: regionNamePrefix
    defaultTags: defaultTags
  }
}

module modVWANHub '../Modules/moduleVWANHub.bicep' = {
  dependsOn: [
    modVNETs
  ]
  scope: rsg
  name: 'deployVWANHub'
  params: {
    region: region
    regionNamePrefix: regionNamePrefix
    defaultTags: defaultTags
    deployVPNGateway: deployVPNGateway
    vwanHubCIDR: vwanHubCIDR
    vnets: vnets
    vwanName: modVWAN.outputs.vwanName
  }
}
