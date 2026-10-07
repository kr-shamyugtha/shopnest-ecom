output "state_bucket_name" {
  description = "S3 bucket containing Terraform state."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket containing Terraform state."
  value       = aws_s3_bucket.state.arn
}

output "region" {
  description = "AWS region containing the Terraform state backend."
  value       = var.region
}

output "account_id" {
  description = "AWS account the state backend was created in."
  value       = data.aws_caller_identity.current.account_id
}
