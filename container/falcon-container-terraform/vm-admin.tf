resource "azurerm_public_ip" "public-ip" {
  name                = "${var.prefix}-${var.vmname}-pub-ip"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  tags = var.tags
}

resource "azurerm_network_security_group" "vm-nsg" {
  name                = "${var.prefix}-${var.vmname}-nsg"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  security_rule {
    name                       = "allow-ssh"
    description                = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.tags
}

resource "azurerm_network_interface" "net-interface" {
  name                = "${var.prefix}-${var.vmname}-net-interface"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  ip_configuration {
    name                          = "${var.prefix}-${var.vmname}-ip"
    subnet_id                     = azurerm_subnet.subnet-internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public-ip.id
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "nsg-association" {
  network_interface_id      = azurerm_network_interface.net-interface.id
  network_security_group_id = azurerm_network_security_group.vm-nsg.id
}

resource "azurerm_linux_virtual_machine" "linux" {
  name                = "${var.prefix}-${var.vmname}"
  resource_group_name = azurerm_resource_group.resource-group.name
  location            = azurerm_resource_group.resource-group.location
  size                = "Standard_B1s"
  admin_username      = "azadmin"
  network_interface_ids = [
    azurerm_network_interface.net-interface.id,
  ]

  custom_data = base64encode(
    length(data.template_file.admin-vm-script[*]) > 0
    ? data.template_file.admin-vm-script[0].rendered
    : data.template_file.admin-vm-script-ds[0].rendered
    )

  admin_ssh_key {
    username   = "azadmin"
    public_key = file(var.ssh_key_pub)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

data "template_file" "admin-vm-script" {
  count = var.deploy_lumos ? 1 : 0
  template = file("vm-admin.sh.tpl")
  
  vars = {
    AKS_CLUSTER_NAME = azurerm_kubernetes_cluster.aks.name
    ACR_LOGIN_SERVER = azurerm_container_registry.acr.login_server
    RG_NAME = azurerm_resource_group.resource-group.name
    VAULT_NAME = azurerm_key_vault.key_vault.name
  }
}

data "template_file" "admin-vm-script-ds" {
  count = var.deploy_lumos ? 0 : 1
  template = file("vm-admin.ds.sh.tpl")
  
  vars = {
    AKS_CLUSTER_NAME = azurerm_kubernetes_cluster.aks.name
    ACR_LOGIN_SERVER = azurerm_container_registry.acr.login_server
    RG_NAME = azurerm_resource_group.resource-group.name
    VAULT_NAME = azurerm_key_vault.key_vault.name
  }
}
