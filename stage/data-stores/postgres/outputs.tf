output "address" {
    value       = aws_db_instance.terraformdb.address
    description = "Connect to the database at this endpoint"
}

output "port" {
    value       = aws_db_instance.terraformdb.port
    description = "The port the database is listening on"
}