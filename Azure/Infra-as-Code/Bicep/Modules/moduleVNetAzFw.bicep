targetScope = 'resourceGroup'

@description('Azure Region to deploy to - use CLI name e.g. "uksouth"')
param region string = 'uksouth'

@description('Naming prefix to use for resources.')
param namingPrefix string

param tags object = {
  'IaC-Source': 'jtracey93/PublicScripts'
}

param vnetCIDR array

param subnetAzFwCIDR string

param subnetAzFwMgmtCIDR string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vnet-${namingPrefix}-azfw-testing'
  location: region
  tags: tags

  properties: {
    addressSpace: {
      addressPrefixes: vnetCIDR
    }
  }
}

resource subnetAzFw 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: subnetAzFwCIDR
  }
  dependsOn: [
    vnet
  ]
}

resource subnetAzFwMgmt 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: 'AzureFirewallManagementSubnet'
  properties: {
    addressPrefix: subnetAzFwMgmtCIDR
  }
  dependsOn: [
    subnetAzFw
  ]
}
