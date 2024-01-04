provider "aws" {
  region = "us-east-2"
}

locals {
  postgres_port = 5432
  local_machine_ip = ["${var.local_ip_address}/32"]
}

# Get default VPC for region
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "postgres_sg" {
  name   = "postgres-sg"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "allow_local_access" {
  type              = "ingress"
  from_port         = local.postgres_port
  to_port           = local.postgres_port
  protocol          = "tcp"
  cidr_blocks       = ["${var.local_ip_address}/32"]
  security_group_id = aws_security_group.postgres_sg.id
}

# AWS Secrets Manager
resource "aws_db_instance" "terraform-db" {
  identifier_prefix   = "mcintosh-terraform-db"
  engine              = "postgres"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  publicly_accessible = true  # Allows access from local IP address
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]

  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
}