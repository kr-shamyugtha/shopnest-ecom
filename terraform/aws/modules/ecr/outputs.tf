output "repository_arns" {
  value = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_urls" {
  description = "Fully qualified image repositories, e.g. 123456789012.dkr.ecr.eu-central-1.amazonaws.com/shopnest/shopnest-backend"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

# The nearest thing ECR has to ACR's login_server — the per-account registry
# host that `aws ecr get-login-password | docker login` targets.
output "registry_url" {
  value = length(aws_ecr_repository.this) > 0 ? split("/", values(aws_ecr_repository.this)[0].repository_url)[0] : null
}

output "repository_names" {
  value = { for k, v in aws_ecr_repository.this : k => v.name }
}
