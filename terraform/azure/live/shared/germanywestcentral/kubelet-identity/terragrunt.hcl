include "root" {
  path = find_in_parent_folders()
}

locals {
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//kubelet-identity"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name     = "mock-rg"
    location = "germanywestcentral"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "acr" {
  config_path = "../acr"
  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/mock/acr"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name        = local.project_name
  location            = dependency.resource_group.outputs.location
  resource_group_name = dependency.resource_group.outputs.name
  acr_id              = dependency.acr.outputs.id

  tags = {
    ManagedBy = "terraform"
    Project   = local.project_name
  }
}
