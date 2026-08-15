output "cluster_name" {
  value = module.aks.cluster_name
}

output "cluster_id" {
  value = module.aks.cluster_id
}

output "get_credentials_command" {
  value = "az aks get-credentials --resource-group ${data.terraform_remote_state.resource_group.outputs.resource_group_name} --name ${module.aks.cluster_name}"
}

output "kubelet_identity_object_id" {
  value = module.aks.kubelet_identity_object_id
}