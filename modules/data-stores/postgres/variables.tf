variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  sensitive   = true
}

variable "backup_retention_period" {
 description = "Days to retain backups. Must be > 0 to enable replication."
 type = number
 default = null
}
variable "replicate_source_db" {
 description = "If specified, replicate the RDS database at the given ARN."
 type = string
 default = null
}

variable "local_ip_address" {
  description = "Your local machine's ip address to have access to postgres database"
  type        = string
  default     = "67.189.73.239" # Replace with your actual local ip address https://whatismyipaddress.com/
}