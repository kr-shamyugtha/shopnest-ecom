output "name" {
  value = aws_resourcegroups_group.this.name
}

# Named "region" rather than "location" — same role as the Azure module's
# location output: the single place downstream units read the region from.
output "region" {
  value = var.region
}

output "arn" {
  value = aws_resourcegroups_group.this.arn
}

output "tags" {
  value = var.tags
}

output "enable_delete_lock" {
  value = var.enable_delete_lock
}
