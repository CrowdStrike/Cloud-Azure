# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name = var.instance_name
  location = var.location
  resource_group_name = azurerm_resource_group.instancetestrg.name
  network_interface_ids = [
    azurerm_network_interface.myterraformnic.id]
  size = var.size

  os_disk {
    name = var.disk_name
    caching = var.disk_caching
    storage_account_type = var.storage_account_type
  }

source_image_reference {
  publisher = var.image_publisher
  offer = var.image_offer
  sku = var.image_sku
  version = var.image_version
}

  computer_name = var.vm_computer_name
  admin_username = var.vm_admin_username
  disable_password_authentication = var.vm_disable_password_authentication

    admin_ssh_key {
        username       = var.vm_admin_username
        public_key     = tls_private_key.ssh_key.public_key_openssh
    }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = var.env_tags
  }
}

resource "azurerm_virtual_machine_extension" "myterraformvm" {
  name = "falcon-sensor-install-linux"
  virtual_machine_id = azurerm_linux_virtual_machine.myterraformvm.id
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"
  ## TODO: work the variables into KeyVault
  protected_settings = <<PROTECTED
  {
    "fileUris": [
          "https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh"
        ],
    "commandToExecute": "export FALCON_CID=${var.falcon_cid} && export FALCON_CLIENT_ID=${var.falcon_client_id} && export FALCON_CLIENT_SECRET=${var.falcon_client_secret} && export FALCON_CLOUD=${var.falcon_cloud} && /bin/bash falcon-linux-install.sh"
  }
  PROTECTED

  tags = {
    environment = var.env_tags
  }
}
