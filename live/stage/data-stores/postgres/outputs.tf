output "address" {
  value       = module.postgres.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = module.postgres.port
  description = "The port the database is listening on"
}