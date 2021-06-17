resource "azurerm_key_vault" "key_vault" {
    name = "${var.prefix}-keyvault${var.suffix}"
    resource_group_name = azurerm_resource_group.resource-group.name
    location = azurerm_resource_group.resource-group.location
    tenant_id = "${data.azurerm_client_config.current.tenant_id}"
    sku_name = "standard"
    soft_delete_retention_days = 7
    tags = var.tags
}

 resource "azurerm_key_vault_access_policy" "my_access" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = var.object_id
  certificate_permissions = [ "get" ]
  storage_permissions = [ "get" ]
  key_permissions = [ 
    "get", 
    "create" 
    ]
  secret_permissions = [ 
    "Set",
    "Get",
    "list",
    "Delete",
    "Purge",
    "Recover"
    ]
}

 resource "azurerm_key_vault_access_policy" "vm_access" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_linux_virtual_machine.linux.identity[0].principal_id
  secret_permissions = [ "Get" ]
}

resource "azurerm_key_vault_secret" "falcon_cid" {
  depends_on = [azurerm_key_vault_access_policy.my_access]
  name         = "falcon-cid"
  value        = "${var.falcon_cid}"
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "falcon_client_id" {
  depends_on = [azurerm_key_vault_access_policy.my_access]
  name         = "falcon-client-id"
  value        = "${var.falcon_client_id}"
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "falcon_client_secret" {
  depends_on = [azurerm_key_vault_access_policy.my_access]
  name         = "falcon-client-secret"
  value        = "${var.falcon_client_secret}"
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "falcon_cloud" {
  depends_on = [azurerm_key_vault_access_policy.my_access]
  name         = "falcon-cloud"
  value        = "${var.falcon_cloud}"
  key_vault_id = azurerm_key_vault.key_vault.id
}
