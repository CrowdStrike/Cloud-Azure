variable "falcon_cid" {
    type = string
    default = ""
}

variable "falcon_client_id" {
    type = string
}

variable "falcon_client_secret" {
    type = string
}

variable "falcon_cloud" {
    type = string
    default = ""
    description = "Place value of Falcon cloud platform variable if not us-1"
}

variable "instance_name" {
	type = string
    default = "MyLinuxInstance"
}

variable "vnetName" {
    type = string
    default = "agent-test"
}

variable "subnetName" {
    type = string
    default = "agent-test-subnet"
}

variable "location" {
    type = string
    default = "eastus"
}

variable "nsgName" {
    type = string
    default = "agent-test-nsg"
}

variable "resourceGroupName" {
    type = string
    default = "agent-test-rg"
}

variable "env_tags" {
    type = string
    default = "Demo Agent Install"
}

variable "size" {
    type = string
    default = "Standard_DS1_v2"
}

variable "disk_name" {
    type = string
    default = "myOsDisk"
}

variable "disk_caching" {
    type = string
    default = "ReadWrite"
}

variable "storage_account_type" {
    type = string
    default = "Premium_LRS"
}

variable "image_publisher" {
    type = string
    default = "Canonical"
}

variable "image_offer" {
    type = string
    default = "UbuntuServer"
}

variable "image_sku" {
    type = string
    default = "18.04-LTS"
}

variable "image_version" {
    type = string
    default = "latest"
}

variable "vm_computer_name" {
    type = string
    default = "mylinuxsystem"
}

variable "vm_admin_username" {
    type = string
    default = "azureuser"
}

variable "vm_disable_password_authentication" {
    type = bool
    default = true
}