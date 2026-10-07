# Present here purely so the IDE / a direct `terraform init` sees the same
# version pins Terragrunt's root generate "versions" block produces — when
# actually run through Terragrunt, this file gets overwritten by that
# generated one during the module-source copy, so it has zero effect on the
# real apply path. Keep both in sync.
#
# The tls provider is the one requirement this module has that the root
# block does not declare, because only this module reads the OIDC issuer's
# certificate to compute its thumbprint. Terragrunt's generated file
# replaces this one, so tls must also be present in the root config for a
# real apply to work.
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
