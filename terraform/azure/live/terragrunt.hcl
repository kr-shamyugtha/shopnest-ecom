locals {
  project_name = "shopnest"
}

remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    resource_group_name  = "shopnest-tfstate-rg"
    storage_account_name = "shopnesttfstate001"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<PROVIDER
provider "azurerm" {
  features {}
}
PROVIDER
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<VERSIONS
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}
VERSIONS
}

inputs = {
  project_name = local.project_name
}
