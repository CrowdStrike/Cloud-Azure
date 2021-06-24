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

variable "vm_name" {
    type = string
}

variable "falcon_cloud" {
    type = string
    default = "us-1"
    validation {
        condition     = (var.falcon_cloud == "us-1" || var.falcon_cloud == "us-2" || var.falcon_cloud == "eu-1" || var.falcon_cloud == "us-gov-1")
        error_message = "Variable falcon_cloud must be set to one of: us-1, us-2, eu-1, us-gov-1."
    }
}

variable "password"{
    type=string
}