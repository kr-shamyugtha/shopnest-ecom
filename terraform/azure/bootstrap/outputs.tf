output "resource_group_name" {
  description = "Resource group holding the Terraform state backend"
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Storage account holding the Terraform state file"
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Blob container holding the Terraform state file"
  value       = azurerm_storage_container.state.name
}

output "next_steps" {
  description = "Instructions for what to do next"
  value = <<-EOT

  ========================================
  Terraform State Backend Created!
  ========================================

  Resource Group:  ${azurerm_resource_group.state.name}
  Storage Account: ${azurerm_storage_account.state.name}
  Container:       ${azurerm_storage_container.state.name}
  Region:          ${azurerm_resource_group.state.location}

  ========================================
  Next Steps:
  ========================================

  1. Update terraform/azure/backend.tf with:

     terraform {
       backend "azurerm" {
         resource_group_name  = "${azurerm_resource_group.state.name}"
         storage_account_name = "${azurerm_storage_account.state.name}"
         container_name       = "${azurerm_storage_container.state.name}"
         key                  = "shopnest.tfstate"
       }
     }

  2. Initialize the real infrastructure:

     cd ../
     terraform init

  ========================================

  EOT
}