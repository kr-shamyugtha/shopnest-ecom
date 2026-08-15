data "terraform_remote_state" "resource_group" {
  backend = "azurerm"
  config = {
    resource_group_name  = "shopnest-tfstate-rg"
    storage_account_name = "shopnesttfstate001"
    container_name       = "tfstate"
    key                  = "dev/germanywestcentral/resource-group.tfstate"
  }
}

data "terraform_remote_state" "aks" {
  backend = "azurerm"
  config = {
    resource_group_name  = "shopnest-tfstate-rg"
    storage_account_name = "shopnesttfstate001"
    container_name       = "tfstate"
    key                  = "dev/germanywestcentral/aks.tfstate"
  }
}

module "keyvault" {
  source                          = "../../../../modules/keyvault"
  project_name                    = var.project_name
  location                        = data.terraform_remote_state.resource_group.outputs.resource_group_location
  resource_group_name             = data.terraform_remote_state.resource_group.outputs.resource_group_name
  aks_kubelet_identity_object_id  = data.terraform_remote_state.aks.outputs.kubelet_identity_object_id
  tags = {
    ManagedBy   = "terraform"
    Environment = var.environment
    Project     = var.project_name
  }
}