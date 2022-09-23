@description('Azure region to deploy to')
param region string = 'uksouth'

@description('Azure region naming prefix')
param regionNamePrefix string = 'uks'

@description('Tags to apply to applicable resoruces')
param defaultTags object = {
  'IaC-Source': 'jtracey93/PublicScripts'
}

resource vwan 'Microsoft.Network/virtualWans@2021-02-01' = {
  name: 'vwan-${regionNamePrefix}'
  location: region
  tags: defaultTags
  properties: {
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    disableVpnEncryption: false
    type: 'Standard'
  }  
}

output vwanName string = vwan.name
