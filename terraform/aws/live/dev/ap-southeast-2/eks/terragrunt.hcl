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
    region = "ap-southeast-2"
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

# Counterpart to the Azure dev unit's hardcoded ci_principal_id. Only dev
# grants the pipeline in-cluster access, matching the Azure side.
dependency "ci_identity" {
  config_path = "../../../shared/ap-southeast-2/ci-identity"
  mock_outputs = {
    principal_arn = "arn:aws:iam::000000000000:user/mock-ci-user"
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

  # Same minor as the AKS dev cluster. 1.31 (the earlier pin) is past
  # standard support, which EKS bills at 6x the control-plane rate.
  kubernetes_version = "1.35"
  # The AWS Free plan only launches Free Tier eligible instance types
  # (`aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true`).
  # t3.large is refused at RunInstances time, which surfaces as a node group
  # stuck in CREATING with no instances. m7i-flex.large is the eligible type
  # with the same 2 vCPU / 8 GiB.
  instance_type      = "m7i-flex.large"

  enable_auto_scaling = true
  min_count           = 2
  max_count           = 2

  # Counterpart to admin_group_object_ids. AWS has no group principal an EKS
  # access entry can name — it takes an IAM role or user ARN. On this AWS
  # Free plan account there is no IAM Identity Center to supply a role, so
  # the admin is the IAM user that runs Terragrunt; the add-on units also
  # reach the cluster as that identity (`aws eks get-token`).
  admin_principal_arns = [
    "arn:aws:iam::${get_aws_account_id()}:user/shamyugtha-admin",
  ]

  ci_principal_arn = dependency.ci_identity.outputs.principal_arn

  enable_delete_lock = false
  support_type       = "STANDARD"

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
