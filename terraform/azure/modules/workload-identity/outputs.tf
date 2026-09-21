output "client_id" {
  description = <<-EOT
    Client ID of the managed identity. This is what goes into the
    Kubernetes ServiceAccount's azure.workload.identity/client-id
    annotation and the SecretProviderClass's clientID parameter. It is an
    identifier, not a secret — it grants nothing without a token the
    cluster signs for the federated ServiceAccount.
  EOT
  value       = azurerm_user_assigned_identity.this.client_id
}

output "principal_id" {
  description = <<-EOT
    Object ID of the managed identity's service principal. This is what
    Azure role assignments must reference (for example granting Key Vault
    Secrets User) — not the client ID.
  EOT
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "id" {
  description = "Full Azure resource ID of the managed identity"
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "Name of the managed identity"
  value       = azurerm_user_assigned_identity.this.name
}
