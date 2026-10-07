output "role_arn" {
  description = "ARN the GitHub Actions workflow assumes. Set this as the AWS_ROLE_ARN repository variable."
  value       = aws_iam_role.ci.arn
}

output "role_name" {
  value = aws_iam_role.ci.name
}

# Counterpart to the Azure units' hardcoded ci_principal_id — the identity
# the eks and ecr modules grant access to.
output "principal_arn" {
  value = aws_iam_role.ci.arn
}

output "oidc_provider_arn" {
  value = local.oidc_provider_arn
}
