include "root" {
  path = find_in_parent_folders()
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region      = local.region_vars.locals.region
}

terraform {
  source = "${get_repo_root()}/terraform/aws/modules//cert-manager"
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    host                   = "https://mock.example.com"
    cluster_ca_certificate = "bW9jaw=="
    cluster_name           = "mock-cluster"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  cluster_host           = dependency.eks.outputs.host
  cluster_ca_certificate = dependency.eks.outputs.cluster_ca_certificate
  cluster_name           = dependency.eks.outputs.cluster_name
  region                 = local.region
}
