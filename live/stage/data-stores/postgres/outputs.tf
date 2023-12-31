output "address" {
  value       = module.postgres.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = module.postgres.port
  description = "The port the database is listening on"
}

output "db_credentials_secret_arn" {
  value     = aws_secretsmanager_secret.db_credentials_secrets_copy.arn
  description = "The ARN of the secret containing the database credentials"
  sensitive = true
}