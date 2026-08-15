location              = "germanywestcentral"
environment            = "dev"
project_name           = "shopnest"
resource_group_name    = "shopnest-tfstate-rg"
storage_account_name   = "shopnesttfstate001"
container_name          = "tfstate"
enable_versioning      = true

tags = {
  ManagedBy   = "terraform"
  Environment = "dev"
  Purpose     = "terraform-state-backend"
  Project     = "shopnest"
}