# Counterpart to vault_uri/vault_name — what the SecretProviderClass needs
# to address these secrets.
output "secret_prefix" {
  description = "Path prefix every secret is stored under, e.g. shopnest/dev. The Helm chart joins this with each items[].name."
  value       = local.prefix
}

output "secret_arns" {
  value = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secret_names" {
  value = { for k, v in aws_secretsmanager_secret.this : k => v.name }
}

output "kms_key_arn" {
  value = aws_kms_key.this.arn
}

output "backend_read_policy_arn" {
  value = aws_iam_policy.backend_read.arn
}
