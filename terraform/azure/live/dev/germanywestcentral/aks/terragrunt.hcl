include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//aks"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name     = "mock-rg"
    location = "germanywestcentral"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    aks_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-aks-subnet"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "acr" {
  config_path = "../../../shared/germanywestcentral/acr"
  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/mock/acr"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name         = local.project_name
  environment         = local.environment
  location             = dependency.resource_group.outputs.location
  resource_group_name  = dependency.resource_group.outputs.name
  subnet_id            = dependency.networking.outputs.aks_subnet_id
  acr_id = dependency.acr.outputs.id
  admin_group_object_ids = [
  "190544d6-0159-4194-aefe-10600507b1e4"
]
  # sc-shopnest-azure Azure DevOps service connection's actual OIDC identity:
  # the SERVICE PRINCIPAL (not the Application object — a different Graph
  # object with a different object ID; role assignments reject Application
  # IDs with "PrincipalTypeNotSupported") for the app Azure DevOps
  # auto-provisioned for workload-identity federation
  # (kavitography-shopnest-ado-34471a29-...), NOT the manually created
  # "shopnest-ci" app, which has no federated credential and can't be used
  # by the service connection at all.
  ci_principal_id = "c4a166f3-2c4d-4bce-9e4e-0880dc154ba5"
  enable_auto_scaling  = true
  min_count            = 2
  max_count            = 2
  vm_size              = "Standard_D2s_v7"
  kubernetes_version   = "1.35"
  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
