# ============================================================================
# CI/CD identity - GitHub Actions -> AWS
# ============================================================================
# Counterpart to terraform/azure/modules/ci-identity. The preferred AWS
# shape is a role GitHub assumes through OIDC, with no long-lived secret —
# but the AWS Free plan's SCP denies iam:CreateOpenIDConnectProvider, so
# that trust cannot exist in this account. The fallback is an IAM user whose
# access key lives only in the repository's AWS_ACCESS_KEY_ID /
# AWS_SECRET_ACCESS_KEY secrets.
#
# What keeps that acceptable is how little the user can do: push to the two
# ShopNest ECR repositories (granted by the ecr module, which owns their
# ARNs) and read the backend workload role's ARN for the GitOps commit.
# Nothing else — no cluster access beyond the namespaced EKS access entry
# the eks module grants, no write access to anything outside ECR.
#
# The access key itself is created outside Terraform (see the README) so
# the secret never lands in the state file.
# ============================================================================

data "aws_caller_identity" "current" {}

resource "aws_iam_user" "ci" {
  name = var.user_name
  path = "/ci/"

  tags = var.tags
}

# ECR push is attached by the ecr module (it owns the repository ARNs).
# This policy covers the rest of what the pipeline does: discover cluster
# endpoints, and read the backend workload role so the GitOps commit can
# write its ARN into the values file — the direct counterpart to
# `az identity show` in ci/azure-pipelines.yml.
data "aws_iam_policy_document" "ci" {
  statement {
    sid    = "DescribeClusters"
    effect = "Allow"

    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ReadBackendWorkloadIdentity"
    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:ListRoleTags",
    ]

    resources = [
      for env in var.workload_identity_environments :
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${env}-backend"
    ]
  }
}

resource "aws_iam_policy" "ci" {
  name        = "${var.user_name}-pipeline"
  description = "Cluster discovery and workload-identity lookup for the ShopNest CI pipeline"
  policy      = data.aws_iam_policy_document.ci.json

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "ci" {
  user       = aws_iam_user.ci.name
  policy_arn = aws_iam_policy.ci.arn
}
