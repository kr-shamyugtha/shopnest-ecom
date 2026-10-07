# ============================================================================
# CI/CD federated identity - GitHub Actions -> AWS
# ============================================================================
# The Azure side has no module for this: Azure DevOps auto-provisions the
# app registration and federated credential behind the sc-shopnest-azure
# service connection, and the terragrunt units just reference the resulting
# service principal's object ID as a hardcoded ci_principal_id.
#
# AWS has no such auto-provisioning, so the trust relationship has to be
# declared here. Same shape as what ADO creates: an OIDC trust, no
# long-lived secret, and a role scoped to exactly what the pipeline does
# (push images, read a cluster's endpoint, read the backend role's ARN).
#
# The narrow in-cluster permissions are granted separately, as an EKS access
# entry in the eks module — mirroring how the Azure side grants "AKS Cluster
# User" and "AKS RBAC Writer" from inside the aks module rather than here.
# ============================================================================

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC endpoint is fronted by a public CA, and IAM stopped
  # verifying this thumbprint for such providers — it is still a required
  # field, so this is GitHub's documented value rather than a live-fetched
  # one. Do not treat a mismatch here as a security control.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn

  # Every ref the pipeline is allowed to assume this role from. Branch refs
  # only by default: a role assumable from `pull_request` would let an
  # unmerged PR push to the shared registry, which is exactly what the Azure
  # pipeline's `ne(variables['Build.Reason'], 'PullRequest')` conditions
  # prevent at the stage level. Enforcing it in the trust policy too means
  # the guard survives someone editing the workflow.
  subjects = [for r in var.allowed_git_refs : "repo:${var.github_repository}:ref:${r}"]
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.subjects
    }
  }
}

resource "aws_iam_role" "ci" {
  name        = var.role_name
  description = "GitHub Actions pipeline role for ShopNest. Assumed via OIDC, no static credentials."

  assume_role_policy = data.aws_iam_policy_document.assume.json

  # A short session is enough for a pipeline run and limits the blast radius
  # of a leaked token from a job log.
  max_session_duration = 3600

  tags = var.tags
}

# ECR push is attached by the ecr module (it owns the repository ARNs).
# This policy covers the rest of what the pipeline does: discover cluster
# endpoints so `aws eks update-kubeconfig` works, and read the backend IRSA
# role so the GitOps commit can write its ARN into the values file — the
# direct counterpart to `az identity show` in ci/azure-pipelines.yml.
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
  name        = "${var.role_name}-pipeline"
  description = "Cluster discovery and workload-identity lookup for the ShopNest CI pipeline"
  policy      = data.aws_iam_policy_document.ci.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ci" {
  role       = aws_iam_role.ci.name
  policy_arn = aws_iam_policy.ci.arn
}
