output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
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