# ACR is one registry holding many repositories; ECR has no registry object —
# each repository is top-level. So the single azurerm_container_registry
# becomes one repository per image, created from a list so the live/ unit
# still configures "the registry" in one place.

locals {
  # ECR is per-account-per-region, so there is no globally-unique name to
  # pick the way "shopnestacr2026" had to be. The repository namespace is
  # the project instead: shopnest/shopnest-backend.
  repositories = { for r in var.repositories : r => "${var.namespace}/${r}" }
}

resource "aws_ecr_repository" "this" {
  for_each = local.repositories

  name = each.value

  # ACR's admin_enabled = false has no ECR equivalent — ECR has no static
  # admin credential at all, only IAM. Nothing to disable.
  image_tag_mutability = var.image_tag_mutability

  # The rough counterpart to ACR's Microsoft Defender scanning. Basic
  # scan-on-push is free; ENHANCED requires Inspector to be enabled in the
  # account. The pipeline's Trivy stage remains the gate either way — this
  # is the always-on backstop for images already sitting in the registry.
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # ACR relies on the resource group's CanNotDelete lock; ECR has a direct
  # per-repository equivalent. force_delete = false means `terraform
  # destroy` refuses while images are still in the repository.
  force_delete = !var.enable_delete_lock

  tags = merge(var.tags, {
    Name = each.value
  })
}

# ACR's Basic SKU caps storage instead of expiring images. ECR bills per GB
# with no cap, so untagged and stale images need an explicit policy or the
# repository grows without bound.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.untagged_image_retention_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_retention_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the most recent ${var.tagged_image_retention_count} release images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["1."]
          countType     = "imageCountMoreThan"
          countNumber   = var.tagged_image_retention_count
        }
        action = { type = "expire" }
      },
    ]
  })
}

# ==========================================================
# Pull access for the environments' clusters
# ==========================================================
#
# The Azure side grants AcrPull to each cluster's kubelet identity from
# inside the aks module — it can do that because the ACR's resource ID is
# passed in as acr_id and role assignments are a separate object. ECR works
# the other way round: access is a policy *on the repository*, so the grant
# has to live here, listing the principals allowed to pull.
resource "aws_ecr_repository_policy" "this" {
  for_each = length(var.pull_principal_arns) > 0 ? aws_ecr_repository.this : {}

  repository = each.value.name
  policy     = data.aws_iam_policy_document.pull[0].json
}

data "aws_iam_policy_document" "pull" {
  count = length(var.pull_principal_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowClusterPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.pull_principal_arns
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
    ]
  }
}

# ==========================================================
# Push access for CI
# ==========================================================
#
# Counterpart to the azurerm_role_assignment granting AcrPush to the
# pipeline's service principal. Expressed as an IAM policy attached to the
# CI role rather than a role assignment scoped to the registry, because
# ecr:GetAuthorizationToken is an account-level action with no resource to
# scope it to — the push actions themselves stay scoped to these
# repositories only.
resource "aws_iam_policy" "ci_push" {
  count = var.ci_role_name != null ? 1 : 0

  name        = "${var.namespace}-ecr-push"
  description = "Push access to the ShopNest ECR repositories, for the CI pipeline"
  policy      = data.aws_iam_policy_document.ci_push[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "ci_push" {
  count = var.ci_role_name != null ? 1 : 0

  statement {
    sid       = "AuthorizeRegistry"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushToShopNestRepositories"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [for r in aws_ecr_repository.this : r.arn]
  }
}

resource "aws_iam_role_policy_attachment" "ci_push" {
  count = var.ci_role_name != null ? 1 : 0

  role       = var.ci_role_name
  policy_arn = aws_iam_policy.ci_push[0].arn
}
