resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting secrets"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "secrets-manager-key"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/secrets-manager"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret" "api_key" {
  name                    = "${var.environment}/api_key"
  description             = "API key for external service"
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 7

  tags = {
    Name        = "api-key"
    Environment = var.environment
    ManagedBy   = "Terraform"
    SecretType  = "api-key"
  }
}

resource "aws_secretsmanager_secret_version" "api_key_value" {
  secret_id = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({
    api_key    = var.api_key_value
    created_at = timestamp()
  })
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.environment}/database/credentials"
  description             = "Database credentials"
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 7

  tags = {
    Name        = "db-credentials"
    Environment = var.environment
    ManagedBy   = "Terraform"
    SecretType  = "database"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_value" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    database = var.db_name
  })
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "${var.environment}/jwt_secret"
  description             = "JWT signing secret"
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 7

  tags = {
    Name        = "jwt-secret"
    Environment = var.environment
    ManagedBy   = "Terraform"
    SecretType  = "jwt"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret_value" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    secret     = var.jwt_secret_value
    algorithm  = "HS256"
    expiration = "24h"
  })
}

resource "aws_iam_policy" "secrets_read" {
  name        = "${var.environment}-secrets-read-policy"
  description = "Policy to allow reading secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.api_key.arn,
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.jwt_secret.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })

  tags = {
    Name        = "secrets-read-policy"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
