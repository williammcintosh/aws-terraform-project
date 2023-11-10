provider "aws" {
  region = "us-east-2"
}

module "postgres" {
  source      = "../../../../modules/data-stores/postgres"
  db_name     = var.db_name
  db_password = var.db_password
  db_username = var.db_username
}

# resource "aws_db_instance" "terraform-db" {
#   identifier_prefix   = "mcintosh-terraform-db"
#   engine              = "postgres"
#   allocated_storage   = 10
#   instance_class      = "db.t3.micro"
#   skip_final_snapshot = true

#   db_name             = var.db_name
#   username            = var.db_username
#   password            = var.db_password
# }

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "prod/data-stores/postgres/terraform.tfstate"
  }
}

