provider "aws" {
  region = "us-east-2"
}

module "postgres" {
  source      = "../../../../modules/data-stores/postgres"
  db_name     = var.db_name
  db_password = var.db_password
  db_username = var.db_username
}

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "live/stage/data-stores/postgres/terraform.tfstate"
  }
}

