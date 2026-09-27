output "id" {
  description = "Resource ID — goes into the aks module's kubelet_identity.user_assigned_identity_id."
  value       = azurerm_user_assigned_identity.kubelet.id
}

output "client_id" {
  description = "Goes into the aks module's kubelet_identity.client_id."
  value       = azurerm_user_assigned_identity.kubelet.client_id
}

output "principal_id" {
  description = "Object ID — goes into the aks module's kubelet_identity.object_id."
  value       = azurerm_user_assigned_identity.kubelet.principal_id
}
