data "terraform_remote_state" "resource_group" {
  backend = "azurerm"
  config = {
    resource_group_name  = "shopnest-tfstate-rg"
    storage_account_name = "shopnesttfstate001"
    container_name       = "tfstate"
    key                  = "dev/germanywestcentral/resource-group.tfstate"
  }
}

module "networking" {
  source              = "../../../../modules/networking"
  project_name        = var.project_name
  location            = data.terraform_remote_state.resource_group.outputs.resource_group_location
  resource_group_name = data.terraform_remote_state.resource_group.outputs.resource_group_name
  tags = {
    ManagedBy   = "terraform"
    Environment = var.environment
    Project     = var.project_name
  }
}