
resource "azurerm_resource_group" "neu-rsg-vwan-001" {
  name     = "neu-rsg-vwan-001"
  location = "North Europe"
}

resource "azurerm_virtual_wan" "vwan-001" {
  name                = "vwan-001"
  resource_group_name = azurerm_resource_group.neu-rsg-vwan-001.name
  location            = azurerm_resource_group.neu-rsg-vwan-001.location

  type = "Standard"
}

resource "azurerm_virtual_hub" "vwan-001-hub-neu" {
  name                = "neu-vwan-hub-001"
  resource_group_name = azurerm_resource_group.neu-rsg-vwan-001.name
  location            = azurerm_resource_group.neu-rsg-vwan-001.location

  virtual_wan_id = azurerm_virtual_wan.vwan-001.id
  address_prefix = "10.255.1.0/24"
}

resource "azurerm_resource_group" "weu-rsg-vwan-001" {
  name     = "weu-rsg-vwan-001"
  location = "West Europe"
}

resource "azurerm_virtual_hub" "vwan-001-hub-weu" {
  name                = "weu-vwan-hub-001"
  resource_group_name = azurerm_resource_group.weu-rsg-vwan-001.name
  location            = azurerm_resource_group.weu-rsg-vwan-001.location

  virtual_wan_id = azurerm_virtual_wan.vwan-001.id
  address_prefix = "10.255.2.0/24"
}


