output "kms_key_id" {
  description = "KMS key ID for secrets encryption"
  value       = aws_kms_key.secrets.id
}

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = aws_kms_key.secrets.arn
}

output "api_key_secret_arn" {
  description = "ARN of the API key secret"
  value       = aws_secretsmanager_secret.api_key.arn
}

output "api_key_secret_name" {
  description = "Name of the API key secret"
  value       = aws_secretsmanager_secret.api_key.name
}

output "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "Name of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

output "jwt_secret_name" {
  description = "Name of the JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.name
}

output "secrets_read_policy_arn" {
  description = "ARN of the IAM policy for reading secrets"
  value       = aws_iam_policy.secrets_read.arn
}

output "secret_retrieval_commands" {
  description = "AWS CLI commands to retrieve secrets"
  value = {
    api_key        = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.api_key.name} --region ${var.region}"
    db_credentials = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_credentials.name} --region ${var.region}"
    jwt_secret     = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.jwt_secret.name} --region ${var.region}"
  }
}
