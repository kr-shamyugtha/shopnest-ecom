include "root" {
  path = find_in_parent_folders()
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region      = local.region_vars.locals.region
}

terraform {
  source = "${get_repo_root()}/terraform/aws/modules//ingress-nginx"
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

# The ingress-nginx Service is annotated for an "external" load balancer,
# which nothing satisfies until the AWS Load Balancer Controller is running.
# Applied first, the Service sits at <pending> EXTERNAL-IP indefinitely
# rather than failing, so this ordering is not optional.
dependency "aws_load_balancer_controller" {
  config_path                             = "../aws-load-balancer-controller"
  mock_outputs                            = {}
  mock_outputs_allowed_terraform_commands = ["validate"]
  skip_outputs                            = true
}

inputs = {
  cluster_host           = dependency.eks.outputs.host
  cluster_ca_certificate = dependency.eks.outputs.cluster_ca_certificate
  cluster_name           = dependency.eks.outputs.cluster_name
  region                 = local.region
}
