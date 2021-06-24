resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-${var.cloud_region}-aks${var.suffix}"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  dns_prefix          = "${var.prefix}${var.cloud_region}aks${var.suffix}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "acrpull_role_aks_agents" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acrpush_role_admin_vm" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_linux_virtual_machine.linux.identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acrpull_role_admin_vm" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_linux_virtual_machine.linux.identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_role_admin_vm_admin" {
  scope                            = azurerm_kubernetes_cluster.aks.id
  role_definition_name             = "Azure Kubernetes Service Cluster Admin Role"
  principal_id                     = azurerm_linux_virtual_machine.linux.identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_role_admin_vm_user" {
  scope                            = azurerm_kubernetes_cluster.aks.id
  role_definition_name             = "Azure Kubernetes Service Cluster User Role"
  principal_id                     = azurerm_linux_virtual_machine.linux.identity[0].principal_id
  skip_service_principal_aad_check = true
}
