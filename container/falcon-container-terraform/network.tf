resource "azurerm_virtual_network" "internal" {
  name                = "${var.prefix}-${var.cloud_region}-network"
  address_space       = var.internal_network_as
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  tags = var.tags
}

resource "azurerm_subnet" "subnet-internal" {
  name                 = "${var.prefix}-${var.cloud_region}-subnet-internal"
  resource_group_name  = azurerm_resource_group.resource-group.name
  virtual_network_name = azurerm_virtual_network.internal.name
  address_prefixes     = var.internal_network_sn
}
