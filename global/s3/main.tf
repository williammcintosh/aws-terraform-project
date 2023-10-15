provider "aws" {
    region = "us-east-2"
}

# Create an S3 bucket to store the terraform state
resource "aws_s3_bucket" "terraform_state" {
    # Rename this below to something very unique
    bucket = "mcintosh-terraform-state-storage"
    # Prevent accidental deletion of this S3 bucket
    lifecycle {
        prevent_destroy = true
    }
}

# Enable version history
resource "aws_s3_bucket_versioning" "enabled" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
    bucket = aws_s3_bucket.terraform_state.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

# Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket                  = aws_s3_bucket.terraform_state.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# Create DynamoDB table to lock your state file
resource "aws_dynamodb_table" "terraform_locks" {
    name         = "mcintosh-terraform-state-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

# The remainder of this config is in global/config/backend.hcl 
terraform {
  # Reminder this is partial config, must use either:
  # $ terraform init -backend-config=../config/backend.hcl (without justfile)
  # $ just init (with justfile)
  backend "s3" {
    key = "global/s3/terraform.tfstate"
  }
}