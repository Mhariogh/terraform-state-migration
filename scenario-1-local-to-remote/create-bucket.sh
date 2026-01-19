#!/bin/bash
# Create S3 bucket for state storage
# ===================================
# Run this before migrating state to S3

BUCKET_NAME="terraform-state-migration-demo"
ENDPOINT="http://localhost:4566"

echo "Creating S3 bucket for Terraform state..."

# Create bucket
aws s3 mb s3://$BUCKET_NAME \
  --endpoint-url $ENDPOINT \
  2>/dev/null

# Enable versioning (best practice)
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled \
  --endpoint-url $ENDPOINT \
  2>/dev/null

echo "✅ Bucket '$BUCKET_NAME' created and versioning enabled"
echo ""
echo "Next steps:"
echo "1. Uncomment the backend block in backend.tf"
echo "2. Run: terraform init -migrate-state"
echo "3. Answer 'yes' to copy existing state"
