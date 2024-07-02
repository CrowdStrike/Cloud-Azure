resource "azurerm_storage_account" "quick_scan_storage_account" {
  name = "${var.project}demostorage"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "quick_scan_storage_container" {
  name                  = "quickscancontainer"
  storage_account_name  = azurerm_storage_account.quick_scan_storage_account.name
  container_access_type = "private"
}
