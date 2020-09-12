param namePrefix string = 'csvtojson'
param region string = 'northeurope'
param defaultTags object = {
    SourceGitHubRepo: 'https://github.com/jtracey93/PublicScripts'
    Service: 'CSVToJSON PowerShell Function'
}

var sacName = '${namePrefix}sacfunc001'
var funcappsvcplanname = '${namePrefix}appsvcplan001'
var appinsightsname = '${namePrefix}appins001'
var funcappname = '${namePrefix}funcapp001'

resource sacfunc001 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: sacName
  location: region
  tags: defaultTags
  kind: 'StorageV2'
  sku: {
      name: 'Standard_LRS'
  }
}

resource funcappsvcplan001 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: funcappsvcplanname
  location: region
  tags: defaultTags
  kind: 'functionapp'
  sku: {
      name: 'Y1'
      tier: 'Dynamic'
  }
  properties: {
      name: funcappsvcplanname
      computeMode: 'Dynamic'
  }
}

resource appinsightsfunc001 'Microsoft.insights/components@2018-05-01-preview' = {
  name: appinsightsname
  location: region
  tags: defaultTags
  kind: 'web'
  properties: {
    ApplicationId: appinsightsname
    Application_Type: 'web'
  }
}

resource funcapp001 'Microsoft.Web/sites@2019-08-01' = {
  name: funcappname
  location: region
  tags: defaultTags
  kind: 'functionapp'
  properties: {
      serverFarmId: funcappsvcplan001.id
      siteConfig: {
          appSettings: [
              {
                  name: 'AzureWebJobsStorage'
                  value: 'DefaultEndpointsProtocol=https;AccountName=${sacName};AccountKey=${listKeys(sacfunc001.id, sacfunc001.apiVersion).keys[0].value}'
              }
              {
                  name: 'FUNCTIONS_EXTENSION_VERSION'
                  value: '~3'
              }
              {
                  name: 'FUNCTIONS_WORKER_RUNTIME'
                  value: 'powershell'
              }
              {
                  name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
                  value: 'DefaultEndpointsProtocol=https;AccountName=${sacName};AccountKey=${listKeys(sacfunc001.id, sacfunc001.apiVersion).keys[0].value}'
              }
              {
                  name: 'WEBSITE_CONTENTSHARE'
                  value: funcappname
              }
              {
                  name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
                  value: appinsightsfunc001.properties.InstrumentationKey
              }
          ]
      }
  }
}