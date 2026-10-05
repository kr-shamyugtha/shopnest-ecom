# ============================================================================
# Secrets Manager - the Key Vault counterpart
# ============================================================================
# Key Vault is a container holding many secrets; Secrets Manager has no
# container object, so the vault becomes a naming prefix ("shopnest/dev/")
# and each entry is its own secret. The Helm chart's secrets.items list is
# unchanged between clouds — only the prefix differs, which is what
# secrets.aws.secretPrefix carries in the values files.
# ============================================================================

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  prefix = "${var.project_name}/${var.environment}"

  secrets = { for name in var.secret_names : name => "${local.prefix}/${name}" }
}

# A customer-managed key rather than the default aws/secretsmanager key, so
# access can be revoked at the key as well as at the secret — the closest
# equivalent to Key Vault's purge_protection_enabled being a property of the
# vault rather than of each secret.
resource "aws_kms_key" "this" {
  description             = "Encryption for ${local.prefix} application secrets"
  enable_key_rotation     = true
  deletion_window_in_days = var.enable_delete_lock ? 30 : 7

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_secretsmanager_secret" "this" {
  for_each = local.secrets

  name        = each.value
  description = "ShopNest ${var.environment} — ${each.key}"
  kms_key_id  = aws_kms_key.this.arn

  # Key Vault's soft_delete_retention_days = 7, expressed per-secret.
  # Protected environments get the maximum window instead.
  recovery_window_in_days = var.enable_delete_lock ? 30 : 7

  tags = merge(var.tags, {
    Name = each.value
  })
}

# Deliberately no aws_secretsmanager_secret_version resources: putting a
# value in Terraform means putting it in the state file. The Azure module
# takes the same position — it creates the vault and the access grants, and
# the secret values are populated out of band. Seed them once with:
#
#   aws secretsmanager put-secret-value \
#     --secret-id shopnest/dev/MONGO-URI --secret-string '...'

# ==========================================================
# Read access for the backend workload identity
# ==========================================================
#
# Counterpart to the "Key Vault Secrets User" role assignment. Scoped to
# these secrets' ARNs only, so the role cannot read another environment's
# secrets even though they live in the same account.

data "aws_iam_policy_document" "backend_read" {
  statement {
    sid    = "ReadShopNestSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = [for s in aws_secretsmanager_secret.this : s.arn]
  }

  statement {
    sid    = "DecryptWithSecretsKey"
    effect = "Allow"

    actions = ["kms:Decrypt"]

    resources = [aws_kms_key.this.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "backend_read" {
  name        = "${var.project_name}-${var.environment}-backend-secrets-read"
  description = "Read access to the ShopNest ${var.environment} application secrets"
  policy      = data.aws_iam_policy_document.backend_read.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_read" {
  role       = var.backend_identity_role_name
  policy_arn = aws_iam_policy.backend_read.arn
}

# ==========================================================
# Write access for whoever seeds the values
# ==========================================================
#
# Counterpart to the "Key Vault Secrets Officer" assignment the Azure module
# gives to the currently-authenticated identity. Made an explicit input here
# rather than inferred from the caller, so a Terragrunt run from CI does not
# silently hand the pipeline write access to production secrets.

data "aws_iam_policy_document" "secrets_officer" {
  count = length(var.secrets_officer_principal_arns) > 0 ? 1 : 0

  statement {
    sid    = "ManageShopNestSecretValues"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.secrets_officer_principal_arns
    }

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DescribeSecret",
    ]

    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "this" {
  for_each = length(var.secrets_officer_principal_arns) > 0 ? aws_secretsmanager_secret.this : {}

  secret_arn = each.value.arn
  policy     = data.aws_iam_policy_document.secrets_officer[0].json
}
