# The container registry name needs to be globally 
# unique and may be a stciking point.
resource "azurerm_container_registry" "acr" {
  name                          = "${var.prefix}ContainerRegistry${var.suffix}01"
  resource_group_name           = azurerm_resource_group.resource-group.name
  location                      = azurerm_resource_group.resource-group.location
  sku                           = "Standard"
  admin_enabled                 = false
  tags = var.tags
}