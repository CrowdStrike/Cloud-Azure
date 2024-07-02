variable "project" {
  type = string
  description = "Project name"
}


variable "location" {
  type = string
  description = "Azure region to deploy module to"
}

variable "falcon_client_id" {
  description = "The CrowdStrike Falcon API client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "falcon_client_secret" {
  description = "The CrowdStrike Falcon API client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "base_url" {
  description = "The Base URL for the CrowdStrike Cloud API"
  type        = string
  default     = "https://api.crowdstrike.com"
}

variable "function_mitigate_threats" {
  description = "Remove malicious files from the bucket as they are discovered."
  type        = string
  default     = "TRUE"
}

variable "quick_scan_storage_account_name" {
  description = "Name of the storage account which the container to be monitored resides."
  type        = string
}


variable "quick_scan_storage_account_container_name" {
  description = "Name of the storage container to be monitored."
  type        = string
}

variable "quick_scan_storage_account_resource_group" {
  description = "Resource group where storage account to be monitored resides."
  type        = string
}

# Existing storage account
data "azurerm_storage_account" "quick_scan_storage_account" {
  name                = "${var.quick_scan_storage_account_name}"
  resource_group_name = "${var.quick_scan_storage_account_resource_group}"
}
