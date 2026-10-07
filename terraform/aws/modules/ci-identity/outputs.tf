output "user_name" {
  description = "Create its access key with `aws iam create-access-key --user-name <this>` and store it as the AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY repository secrets."
  value       = aws_iam_user.ci.name
}

# Counterpart to the Azure units' ci_principal_id — the identity the eks
# and ecr modules grant access to.
output "principal_arn" {
  value = aws_iam_user.ci.arn
}
