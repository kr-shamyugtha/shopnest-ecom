terraform {
  backend "azurerm" {
    resource_group_name  = "shopnest-tfstate-rg"
    storage_account_name = "shopnesttfstate001"
    container_name       = "tfstate"
    key                  = "dev/germanywestcentral/resource-group.tfstate"
  }
}