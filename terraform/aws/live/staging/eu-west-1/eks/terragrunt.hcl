include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/aws/modules//eks"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name   = "mock-rg"
    region = "eu-west-1"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    private_subnet_ids        = ["subnet-mock1", "subnet-mock2"]
    cluster_security_group_id = "sg-mock"
    vpc_id                    = "vpc-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name        = local.project_name
  environment         = local.environment
  region              = dependency.resource_group.outputs.region
  resource_group_name = dependency.resource_group.outputs.name

  private_subnet_ids        = dependency.networking.outputs.private_subnet_ids
  cluster_security_group_id = dependency.networking.outputs.cluster_security_group_id

  kubernetes_version = "1.35"
  instance_type      = "t3.large"

  enable_auto_scaling = true
  min_count           = 2
  max_count           = 2

  # Counterpart to admin_group_object_ids. AWS has no group principal an EKS
  # access entry can name — it takes an IAM role or user ARN — so the Entra
  # ID group becomes an IAM role that the admins assume (directly, or as an
  # IAM Identity Center permission set). Mirrors the Azure split: dev and
  # staging share one admins role, prod has its own.
  admin_principal_arns = [
    "arn:aws:iam::${get_aws_account_id()}:role/shopnest-eks-admins",
  ]

  enable_delete_lock = true
  support_type       = "EXTENDED"

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
