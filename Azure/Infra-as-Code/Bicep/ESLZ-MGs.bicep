targetScope = 'tenant'

@description('Provide prefix for the Management Group hierarchy.')
@maxLength(5)
@minLength(2)
param prefix string = 'ES'

@description('These are the child Platform Management Groups')
param lzChildMGs array = [
  'corp'
  'online'
  'sap'
]

@description('These are the child Landing Zone Management Groups')
param platformChildMGs array = [
  'management'
  'connectivity'
  'identity'
]

var eslzManagementGroups = {
  platform: '${prefix}-platform'
  landingzones: '${prefix}-landingzones'
  decommissioned: '${prefix}-decommissioned'
  sandboxes: '${prefix}-sandoxes'
}

// Create intermediate root Management Group
resource intRootMG 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: prefix
  properties: {
    displayName: prefix
  }
}

// Create platform Management Group
resource platformMG 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: eslzManagementGroups.platform
  properties: {
    displayName: eslzManagementGroups.platform
    details: {
      parent: {
        id: intRootMG.id
      }
    }
  }
}

// Create child Management Groups for platform 
resource platformMGsCopy 'Microsoft.Management/managementGroups@2020-05-01' = [for mg in platformChildMGs: {
  name: '${prefix}-${mg}'
  properties: {
    displayName: '${prefix}-${mg}'
    details: {
      parent: {
        id: platformMG.id
      }
    }
  }
}]

// Create landing zones Management Group
resource landingZonesMG 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: eslzManagementGroups.landingzones
  properties: {
    displayName: eslzManagementGroups.landingzones
    details: {
      parent: {
        id: intRootMG.id
      }
    }
  }
}

// Create child Management Groups for landing zones 
resource landingZonesMGsCopy 'Microsoft.Management/managementGroups@2020-05-01' = [for mg in lzChildMGs: {
  name: '${prefix}-${mg}'
  properties: {
    displayName: '${prefix}-${mg}'
    details: {
      parent: {
        id: landingZonesMG.id
      }
    }
  }
}]

// Create decommissioned Management Group
resource decommissionedMG 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: eslzManagementGroups.decommissioned
  properties: {
    displayName: eslzManagementGroups.decommissioned
    details: {
      parent: {
        id: intRootMG.id
      }
    }
  }
}

// Create sandbox Management Group
resource sandboxMG 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: eslzManagementGroups.sandboxes
  properties: {
    displayName: eslzManagementGroups.sandboxes
    details: {
      parent: {
        id: intRootMG.id
      }
    }
  }
}
