data "terraform_remote_state" "resource_group" {
  backend = "azurerm"
  config = {
    resource_group_name  = "shopnest-tfstate-rg"
    storage_account_name = "shopnesttfstate001"
    container_name       = "tfstate"
    key                  = "dev/germanywestcentral/resource-group.tfstate"
  }
}

data "terraform_remote_state" "networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = "shopnest-tfstate-rg"
    storage_account_name = "shopnesttfstate001"
    container_name       = "tfstate"
    key                  = "dev/germanywestcentral/networking.tfstate"
  }
}

data "terraform_remote_state" "acr" {
  backend = "azurerm"
  config = {
    resource_group_name  = "shopnest-tfstate-rg"
    storage_account_name = "shopnesttfstate001"
    container_name       = "tfstate"
    key                  = "dev/germanywestcentral/acr.tfstate"
  }
}

module "aks" {
  source              = "../../../../modules/aks"
  project_name        = var.project_name
  location            = data.terraform_remote_state.resource_group.outputs.resource_group_location
  resource_group_name = data.terraform_remote_state.resource_group.outputs.resource_group_name
  subnet_id           = data.terraform_remote_state.networking.outputs.aks_subnet_id
  acr_id              = data.terraform_remote_state.acr.outputs.acr_id
  node_count          = var.node_count
  vm_size             = var.vm_size
  tags = {
    ManagedBy   = "terraform"
    Environment = var.environment
    Project     = var.project_name
  }
}