variable "instance_name" {
	type = string
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

variable "cid" {
    type = string
}

variable "client_id" {
    type = string
}

variable "client_secret" {
    type = string
}

variable "falcon_cloud" {
    type = string
    default = ""
    description = "Place value of falcon cloud platform variable if not us-1"
}

variable "password"{
    type=string
}