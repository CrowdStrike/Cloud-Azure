variable "deploy_lumos" {
  type = bool
  description = "This option should be set to true or false. If set to false the daemonset will be deployed."
}

variable "cloud_region" {
  description = "The Azure cloud region in which to build out resources"
}

variable "object_id" {
  description = "The object_id of the account running terraform"
}

variable "resource_group_name" {
  description = "The name of the Azure resource group used for resources"
}

variable "tags" {
  description = "Default tags used on resources created"
}

variable "suffix" {
  description = "Suffix to provide semi-uniqueness to the objects created. Recommendation is for two or more numbers."
}

variable "vmname" {
  description = "VM Name"
}

variable "prefix" {
  description = "prefix used for semi-unique naming"
}

variable "internal_network_as" {
  description = "Internal network address space"
}

variable "internal_network_sn" {
  description = "Internal network subnet CIDR"
}

variable "your_ip_address" {
  description = "Used for ssh-allow inbound rule on NSG\n\nEnter in CIDR format i.e. 128.128.128.128/32"
}

variable "falcon_client_id" {
  description = "CrowdStrike Falcon / OAuth2 API / Client ID (needs only permissions to download falcon container sensor) (Alternatively, set env variable TF_VAR_falcon_client_id)"
  sensitive   = true
}

variable "falcon_client_secret" {
  description = "CrowdStrike Falcon / OAuth2 API / Client Secret (needs only permissions to download falcon container sensor) (Alternatively, set env variable TF_VAR_falcon_client_secret)"
  sensitive   = true
}

variable "falcon_cloud" {
  description = "Falcon cloud region abbreviation (us-1, us-2, eu-1, us-gov-1) (Alternatively, set env variable TF_VAR_falcon_cloud)"
  validation {
    condition     = (var.falcon_cloud == "us-1" || var.falcon_cloud == "us-2" || var.falcon_cloud == "eu-1" || var.falcon_cloud == "us-gov-1")
    error_message = "Variable falcon_cloud must be set to one of: us-1, us-2, eu-1, us-gov-1."
  }
}

variable "falcon_cid" {
  description = "CrowdStrike Falcon CID (full cid string) (Alternatively, set env variable TF_VAR_falcon_cid)"
  sensitive   = true
}

variable "ssh_key" {
  description = "SSH Public key used for admin vm connection"
  sensitive = true
}

variable "ssh_key_pub" {
  description = "SSH Public key used for admin vm connection"
  sensitive = true
}
