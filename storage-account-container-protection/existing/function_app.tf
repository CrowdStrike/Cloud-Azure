data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "../function-app"
  output_path = "function_app.zip"
}


resource "azurerm_linux_function_app" "function_app" {
  name                        = "${var.project}-function-app"
  resource_group_name         = azurerm_resource_group.resource_group.name
  location                    = var.location
  service_plan_id             = azurerm_service_plan.app_service_plan.id
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"            = azurerm_application_insights.application_insights.instrumentation_key,
    "AzureWebJobsStorage"                       = azurerm_storage_account.storage_account.primary_connection_string,
    "FUNCTIONS_WORKER_RUNTIME"                  = "python",
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"  = azurerm_storage_account.storage_account.primary_connection_string,
    "WEBSITE_CONTENTSHARE"                      = "${var.project}-content-share",
    "azurequickscan_STORAGE"                    = data.azurerm_storage_account.quick_scan_storage_account.primary_connection_string,
    "FALCON_CLIENT_ID"                          = var.falcon_client_id,
    "FALCON_CLIENT_SECRET"                      = var.falcon_client_secret,
    "MITIGATE_THREATS"                          = var.function_mitigate_threats,
    "BASE_URL"                                  = var.base_url
    "quick_scan_container_name"                 = var.quick_scan_storage_account_container_name


  }
  site_config {
    application_stack {
      python_version  = "3.11"
    }

  }
  storage_account_name        = azurerm_storage_account.storage_account.name
  storage_account_access_key  = azurerm_storage_account.storage_account.primary_access_key
  functions_extension_version = "~4"

}

locals {
    publish_code_command = "az webapp deployment source config-zip --resource-group ${azurerm_resource_group.resource_group.name} --name ${azurerm_linux_function_app.function_app.name} --src ${data.archive_file.file_function_app.output_path}"
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  depends_on = [local.publish_code_command]
  triggers = {
    input_json = filemd5(data.archive_file.file_function_app.output_path)
    publish_code_command = local.publish_code_command
  }
}