provider "aws" {
    region = "us-east-2"
}

# Create an S3 bucket to store the terraform state
resource "aws_s3_bucket" "terraform_state" {
    # Rename this below to something very unique across the world
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

#==================================================================================
#    DELETED YOUR BUCKET? WANT IT ALL BACK?
#    GOT THE ERROR: "state data in S3 does not have expected data"?
#    No biggie. I got you. Time to nuke.
#
#    1. Delete all of these files/folders in "live/global/s3":
#        .terraform
#        .terraform.lock.hcl
#        terraform.tfstate
#        terraform.tfstate.backup
#    2. In AWS console -> S3 -> delete the bucket.
#    3. In AWS console -> dynamodb delete the dynamodb.
#    4. Comment out the 'terraform' block below, save.
#    5. Run 'terraform init' (not 'just init'!)
#    6. Run 'terraform apply'
#        Doing this should build back the S3 bucket and dynamodb in AWS console
#    7. Uncomment out the 'terraform' block below, save.
#    8. Run 'just init'
#    9. Run 'just apply'
#==================================================================================

terraform {
  backend "s3" {
    key = "global/s3/terraform.tfstate"
  }
}