#terraform block - defining providers we are using
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.61.0"
    }
  }
}

#provider block for credentials to connect with azure
provider "azurerm" {
  features {}
  client_certificate_path = var.client_certificate_path
  subscription_id = var.subscription_id
  client_id = var.client_id
  tenant_id = var.tenant_id
}
