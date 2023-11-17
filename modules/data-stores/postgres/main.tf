provider "aws" {
  region = "us-east-2"
}

# AWS Secrets Manager
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "db-creds"
}

locals {
  #AWS Secrets Manager
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}
resource "aws_db_instance" "terraform-db" {
  identifier_prefix   = "mcintosh-terraform-db"
  engine              = "postgres"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true

  db_name             = var.db_name
  username            = local.db_creds.username
  password            = local.db_creds.password
}