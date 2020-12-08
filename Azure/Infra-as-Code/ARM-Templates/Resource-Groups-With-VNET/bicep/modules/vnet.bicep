param namingPrefix string 
param namingEnvironment string
param region string 
param defaultTags object 
param addressSpace array
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'vnet-${region}-${namingPrefix}-${namingEnvironment}'
  location: region
  properties: {
    addressSpace: {
      addressPrefixes: addressSpace
    }
    subnets: subnets
  }
}

output vnetName string = vnet.name
output vnetID string = vnet.id