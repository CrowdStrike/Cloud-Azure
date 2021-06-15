resource "azurerm_resource_group" "resource-group" {
  name     = "${var.resource_group_name}${var.prefix}${var.cloud_region}${var.suffix}"
  location = var.cloud_region
  tags = var.tags
}

data "azurerm_client_config" "current" {
}
