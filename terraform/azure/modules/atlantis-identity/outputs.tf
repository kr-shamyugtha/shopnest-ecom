output "client_id" {
  description = "Client ID for the Atlantis ServiceAccount's azure.workload.identity/client-id annotation."
  value       = module.identity.client_id
}

output "principal_id" {
  value = module.identity.principal_id
}
