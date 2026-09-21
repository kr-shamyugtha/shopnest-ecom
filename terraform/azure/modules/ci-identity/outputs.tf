output "service_principal_object_id" {
  description = "Object ID of the service principal — this is what role assignments (ci_principal_id) must reference, not the application object ID"
  value       = azuread_service_principal.ci.object_id
}

output "application_client_id" {
  value = azuread_application.ci.client_id
}

output "application_object_id" {
  value = azuread_application.ci.id
}
