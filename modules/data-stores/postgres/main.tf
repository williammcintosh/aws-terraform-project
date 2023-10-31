provider "aws" {
  region = "us-east-2"
}
resource "aws_db_instance" "terraform-db" {
  identifier_prefix   = "mcintosh-terraform-db"
  engine              = "postgres"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true

  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
}