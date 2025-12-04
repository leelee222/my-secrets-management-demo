provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "secrets-management-demo"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}