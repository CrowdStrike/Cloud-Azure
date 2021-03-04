variable "instance_name" {
	type = string
	default = "agent-install-test"
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



variable "password"{
    type=string
}