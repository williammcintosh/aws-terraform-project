output "address" {
  value       = module.postgres.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = module.postgres.port
  description = "The port the database is listening on"
}

output "db_credentials_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials_copy_of_creds_bullshit_again_I_hate_this.arn
}