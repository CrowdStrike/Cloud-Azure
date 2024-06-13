output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
  description = "Deployed function app name"
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.function_app.default_hostname
  description = "Deployed function app hostname"
}

output "demo_storage_account_name"{
  value = "${var.quick_scan_storage_account_name}"
  description = "Deployed quick scan demo storage account name"
}

output "demo_storage_container_name"{
  value = "${var.quick_scan_storage_account_container_name}"
  description = "Deployed quick scan demo storage account name"
}

output "app_insights_app_id" {
  value = azurerm_application_insights.application_insights.app_id
}

output "storage_account_key" {
  value = data.azurerm_storage_account.quick_scan_storage_account.primary_access_key
  description = "Primary Access Key for storage bucket"
  sensitive = true
}
