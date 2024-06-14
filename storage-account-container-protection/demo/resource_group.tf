resource "azurerm_resource_group" "resource_group" {
  name = "${var.project}-resource-group"
  location = var.location
}
