output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL, for federating a new workload identity to a ServiceAccount on this cluster."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Now just echoes var.kubelet_identity_object_id — the identity is fixed by the kubelet_identity block, not auto-generated."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "cluster_identity_principal_id" {
  description = "Object ID of the cluster's own (control-plane) managed identity — not the kubelet identity."
  value       = azurerm_user_assigned_identity.cluster.principal_id
}

output "keyvault_secrets_provider_client_id" {
  description = "Client ID of the Azure Key Vault Secrets Provider managed identity"
  value       = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "keyvault_secrets_provider_object_id" {
  description = "Object ID of the Azure Key Vault Secrets Provider managed identity"
  value       = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
}


output "backend_identity_client_id" {
  description = "Client ID of the ShopNest backend workload identity"
  value       = module.backend_workload_identity.client_id
}

output "backend_identity_object_id" {
  description = "Object ID of the ShopNest backend workload identity"
  value       = module.backend_workload_identity.principal_id
}

output "host" {
  description = "AKS API server endpoint, for configuring Terraform's kubernetes/helm providers"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "AKS cluster CA certificate (base64), for configuring Terraform's kubernetes/helm providers"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}