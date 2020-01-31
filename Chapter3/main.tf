provider "aws" {
    region = "eu-west-2"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "irfan-first-terraform-state"

    # Prevent accidental deletion of this S3 bucket
    lifecycle {
        prevent_destroy = true
    }

    # Enable versioning so we can see full history of state files
    versioning {
        enabled = true
    }

    # Enable server-side encryption by default
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}