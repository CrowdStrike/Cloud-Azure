terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.62.1"
      }
    }
    required_version = "~> 1.0"
}

provider "azurerm" {
  features {
  }
}
