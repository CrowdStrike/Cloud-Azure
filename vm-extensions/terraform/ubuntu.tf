# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name = "${var.instance_name}-ubuntu"
  location = var.location
  resource_group_name = azurerm_resource_group.instancetestrg.name
  network_interface_ids = [
    azurerm_network_interface.myterraformnic.id]
  size = "Standard_DS1_v2"

  os_disk {
    name = "myOsDisk"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }

  computer_name = "${var.instance_name}-ubuntu"
  admin_username = "azureuser"
  disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_machine_extension" "myterraformvm" {
  name = "falcon-sensor-install-linux"
  virtual_machine_id = azurerm_linux_virtual_machine.myterraformvm.id
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  { 
    "protectedSettings": 
    { 
      "fileUris": [ 
          "https://raw.githubusercontent.com/mccbryan3/Cloud-Azure/vm-extension-fix/vm-extensions/scripts/start-falcon-bootstrap.sh"
        ],
        "commandToExecute": "./start-falcon-bootstrap.sh --cid=${var.cid} --client_id=${var.client_id} --client_secret=${var.client_secret}"
    }
  }
  SETTINGS

  tags = {
    environment = "Development"
  }
}