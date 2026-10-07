# AWS has no container object equivalent to an Azure resource group — region
# is a provider setting and resources are grouped by tag, not by parent.
# This module is the closest faithful stand-in and keeps the live/ tree
# structurally identical to terraform/azure/live: it declares the
# environment's tag set once, materialises it as a tag-based AWS Resource
# Group (so the console/CLI can list "everything in shopnest-dev" the way
# the Azure portal lists a resource group), and hands the name/region/tags
# down to every other unit in the environment.
resource "aws_resourcegroups_group" "this" {
  name        = var.name
  description = "All ${var.name} resources, grouped by tag. Terraform-managed."

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        for k, v in var.grouping_tags : {
          Key    = k
          Values = [v]
        }
      ]
    })
  }

  tags = var.tags
}

# The Azure module's enable_delete_lock has no account-level counterpart:
# AWS has no CanNotDelete lock that cascades to every child resource. The
# equivalent protection is applied per-resource instead — see the
# prevent_destroy / deletion-protection / recovery-window settings in the
# ecr, eks and secrets-manager modules, which each read this same flag.
# It is surfaced here only so the live/ units keep the same shape.
