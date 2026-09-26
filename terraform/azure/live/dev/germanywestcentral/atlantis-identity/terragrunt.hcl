include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//atlantis-identity"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name     = "mock-rg"
    location = "germanywestcentral"
    id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "aks" {
  config_path = "../aks"
  mock_outputs = {
    cluster_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.ContainerService/managedClusters/mock-aks"
    oidc_issuer_url = "https://mock.oic.prod-aks.azure.com/mock/"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name        = local.project_name
  environment         = local.environment
  location            = dependency.resource_group.outputs.location
  resource_group_name = dependency.resource_group.outputs.name

  oidc_issuer_url        = dependency.aks.outputs.oidc_issuer_url
  aks_cluster_id         = dependency.aks.outputs.cluster_id
  dev_resource_group_id  = dependency.resource_group.outputs.id
  # shopnest-tfstate-rg isn't a Terragrunt-managed unit in this repo (it
  # predates this IaC setup, per the root backend config's hardcoded
  # storage_account_name) — referenced directly rather than via a
  # dependency block that doesn't exist.
  tfstate_resource_group_id = "/subscriptions/b68fc861-1d2b-40c3-a317-f09c80a001e6/resourceGroups/shopnest-tfstate-rg"

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
