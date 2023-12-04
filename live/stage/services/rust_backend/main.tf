provider "aws" {
	region = "us-east-2"
}

resource "aws_ecr_repository" "app_ecr_repo" {
	name = "rust-backend"
}