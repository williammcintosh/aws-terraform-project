provider "aws" {
  region = "us-east-2"
}

# AWS Secrets Manager
resource "aws_db_instance" "terraform-db" {
  identifier_prefix   = "mcintosh-terraform-db"
  engine              = "postgres"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  publicly_accessible = true  # Allows access from local IP address

  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
}