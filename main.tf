terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# KMS Key for S3 encryption
resource "aws_kms_key" "s3_encryption_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "s3_encryption_key_alias" {
  name          = "alias/s3-encryption-key"
  target_key_id = aws_kms_key.s3_encryption_key.key_id
}

# Secure S3 bucket
resource "aws_s3_bucket" "secure_data_bucket" {
  bucket = "secure-data-bucket-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "secure_data_bucket_pab" {
  bucket = aws_s3_bucket.secure_data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "secure_data_bucket_versioning" {
  bucket = aws_s3_bucket.secure_data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_data_bucket_encryption" {
  bucket = aws_s3_bucket.secure_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "secure_data_bucket_lifecycle" {
  bucket = aws_s3_bucket.secure_data_bucket.id

  rule {
    id     = "transition_to_ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# IAM role for secure access
resource "aws_iam_role" "secure_data_access_role" {
  name = "secure-data-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "secure_data_access_policy" {
  name = "secure-data-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.secure_data_bucket.arn,
          "${aws_s3_bucket.secure_data_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.s3_encryption_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secure_data_access_attachment" {
  role       = aws_iam_role.secure_data_access_role.name
  policy_arn = aws_iam_policy.secure_data_access_policy.arn
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

output "s3_bucket_name" {
  description = "Name of the secure S3 bucket"
  value       = aws_s3_bucket.secure_data_bucket.bucket
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = aws_kms_key.s3_encryption_key.key_id
}

output "iam_role_arn" {
  description = "ARN of the IAM role for secure access"
  value       = aws_iam_role.secure_data_access_role.arn
}

data "aws_caller_identity" "current" {}