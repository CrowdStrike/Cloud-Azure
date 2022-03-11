# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    features {}
}

# Create a resource group if it doesn't exist

resource "azurerm_resource_group" "instancetestrg" {
    name     = var.resourceGroupName
    location = var.location

    tags = {
        environment = var.env_tags
    }
}

# Create virtual network

resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "${var.vnetName}-Vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.instancetestrg.name

    tags = {
        environment = var.env_tags
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = var.subnetName
    resource_group_name  = azurerm_resource_group.instancetestrg.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "${var.vnetName}-pubip"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.instancetestrg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = var.env_tags
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = var.nsgName
    location            = var.location
    resource_group_name = azurerm_resource_group.instancetestrg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = var.env_tags
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "${var.instance_name}-NIC"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.instancetestrg.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = var.env_tags
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgassociation" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.instancetestrg.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.instancetestrg.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = var.env_tags
    }
}

# Create (and display) an SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}





