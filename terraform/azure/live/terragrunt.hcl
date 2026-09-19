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
  storage_account_name = "shopnesttfstate2026"
  container_name       = "tfstate"
  key                  = "${path_relative_to_include()}.tfstate"
  use_azuread_auth = true
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
    # helm/kubernetes are only actually used by ingress-nginx and
    # cert-manager, but a module can only have one required_providers block,
    # and Terragrunt won't let a child unit override this shared, generated
    # one — so they're declared here for every unit. Harmless for the
    # modules that don't use them (just an unused provider requirement).
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}
VERSIONS
}

inputs = {
  project_name = local.project_name
}
