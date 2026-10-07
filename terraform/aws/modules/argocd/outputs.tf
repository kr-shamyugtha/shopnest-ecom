output "grafana_admin_password_secret" {
  description = "Read with: aws secretsmanager get-secret-value --secret-id <this> --query SecretString --output text"
  value       = aws_secretsmanager_secret.grafana_admin_password.name
}
