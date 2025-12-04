variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# API Key Variables
variable "api_key_value" {
  description = "API key value - should be provided securely"
  type        = string
  sensitive   = true
  default     = ""
}

# Database Variables
variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_host" {
  description = "Database host"
  type        = string
  default     = "localhost"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

# JWT Variables
variable "jwt_secret_value" {
  description = "JWT secret for token signing"
  type        = string
  sensitive   = true
  default     = ""
}
