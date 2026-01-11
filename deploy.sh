#!/bin/bash

# Cloud Security Implementation Deployment Script

set -e

echo "Starting Cloud Security Implementation Deployment..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✓ Prerequisites check passed"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Validate Terraform configuration
echo "Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply the configuration
echo "Applying Terraform configuration..."
terraform apply tfplan

# Display outputs
echo "Deployment completed successfully!"
echo "Resource information:"
terraform output

echo "Security implementation deployed with:"
echo "- IAM policies with least privilege access"
echo "- S3 bucket with KMS encryption"
echo "- Public access blocked"
echo "- Versioning enabled"
echo "- Lifecycle policies configured"

echo "Next steps:"
echo "1. Test the secure data manager script"
echo "2. Configure monitoring and alerting"
echo "3. Review security implementation"