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
