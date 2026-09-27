output "grafana_admin_password" {
  description = "Also readable from Key Vault (grafana-admin-password) or `kubectl -n monitoring get secret grafana-admin-credentials`."
  value       = random_password.grafana_admin.result
  sensitive   = true
}
