provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "mcintosh-terraform-db" {
  identifier_prefix   = "mcintosh-terraform-db"
  engine              = "postgres"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = "mem_overflow"
  
  username = var.db_username
  password = var.db_password
}

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "stage/data-stores/postgres/terraform.tfstate"
  }
}