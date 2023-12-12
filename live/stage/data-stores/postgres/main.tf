provider "aws" {
  region = "us-east-2"
}

# bash command to access postgres database form local machine:
# psql -h {DATABASE_ENDPOINT} -p {DATABASE_PORT} -U {DATABASE_USERNAME} -d {DATABASE_NAME}

# AWS Secrets Manager
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "db-creds"
#  secret_id = "db_credentials_secrets_copy"
}


locals {
  #AWS Secrets Manager
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

#resource "aws_secretsmanager_secret" "db_creds" {
#    name = "db-creds"
#}

resource "aws_secretsmanager_secret" "db_credentials_secrets_copy" {
  name = "db_credentials_secrets_copy"
  # kills the newly created db credentials immediately
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials_secrets_copy.id
  secret_string = <<EOF
  {
    "username": "${local.db_creds.username}",
    "password": "${local.db_creds.password}",
    "address": "${module.postgres.address}",
    "port": "${module.postgres.port}"
  }
  EOF
}

module "postgres" {
  source      = "../../../../modules/data-stores/postgres"
  db_name     = var.db_name
  db_password = local.db_creds.password
  db_username = local.db_creds.username
}

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "live/stage/data-stores/postgres/terraform.tfstate"
  }
}

