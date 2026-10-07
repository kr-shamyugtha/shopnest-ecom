output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_id" {
  value = aws_eks_cluster.this.arn
}

output "node_role_arn" {
  description = "The kubelet-identity equivalent. Passed to the ecr module so its repository policy can allow this cluster to pull."
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  value = aws_iam_role.node.name
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider for this cluster's issuer. Any module creating an IRSA role needs this."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_issuer_host" {
  description = "Issuer URL with the https:// scheme stripped, the form IRSA trust-policy conditions require."
  value       = local.oidc_issuer_host
}

output "backend_identity_role_arn" {
  description = "ARN of the ShopNest backend workload identity. Counterpart to backend_identity_client_id — this is what goes into the ServiceAccount's eks.amazonaws.com/role-arn annotation."
  value       = aws_iam_role.backend.arn
}

output "backend_identity_role_name" {
  description = "Counterpart to backend_identity_object_id — what the secrets-manager module attaches its read policy to."
  value       = aws_iam_role.backend.name
}

output "host" {
  description = "EKS API server endpoint, for configuring Terraform's kubernetes/helm providers"
  value       = aws_eks_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64), for configuring Terraform's kubernetes/helm providers"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "kms_key_arn" {
  value = aws_kms_key.secrets.arn
}
