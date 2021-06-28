targetScope = 'subscription'

@description('Azure Region to deploy to - use CLI name e.g. "uksouth"')
param region string = 'uksouth'

@description('Naming prefix to use for resources.')
param namingPrefix string

param tags object = {
  'IaC-Source': 'jtracey93/PublicScripts'
  DemoOf: 'Azure Firewall Subnet Restriction Testing'
}

param vnetCIDR array = [
  '10.0.0.0/16'
]

param subnetAzFwCIDR string = '10.0.1.0/24'

param subnetAzFwMgmtCIDR string = '10.0.2.0/24'

resource rsg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rsg-${namingPrefix}-azfw-testing'
  location: region
  tags: tags
}

module vnetDeploy 'Modules/moduleVNet.bicep' = {
  scope: rsg
  name: 'VNetDeploy'
  params: {
    namingPrefix: namingPrefix
    region: region
    tags: tags
    vnetCIDR: vnetCIDR
    subnetAzFwCIDR: subnetAzFwCIDR
    subnetAzFwMgmtCIDR: subnetAzFwMgmtCIDR
  }
}
