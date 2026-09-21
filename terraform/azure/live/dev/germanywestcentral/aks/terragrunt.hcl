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

dependency "ci_identity" {
  config_path = "../../../shared/germanywestcentral/ci-identity"
  mock_outputs = {
    service_principal_object_id = "00000000-0000-0000-0000-000000000000"
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
  # sc-shopnest-azure Azure DevOps service connection's OIDC identity, now
  # owned by the ci-identity module (imported from the app Azure DevOps
  # originally auto-provisioned — kavitography-shopnest-ado-34471a29-...).
  # Role assignments need the SERVICE PRINCIPAL object ID specifically, not
  # the Application object ID ("PrincipalTypeNotSupported" otherwise).
  ci_principal_id = dependency.ci_identity.outputs.service_principal_object_id
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
