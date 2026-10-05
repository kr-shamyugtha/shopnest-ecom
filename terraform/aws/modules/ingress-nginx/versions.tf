# Present here purely so the IDE / a direct `terraform init` sees the same
# version pins Terragrunt's root generate "versions" block produces (see
# helm-provider.tf) — when actually run through Terragrunt, this file gets
# overwritten by that generated one during the module-source copy, so it has
# zero effect on the real apply path. Keep both in sync.
#
# The helm pin matters: provider v3 dropped the nested `kubernetes` block
# and the `set` blocks this module uses, so an unpinned init resolves to a
# version that cannot parse this configuration at all.
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}
