#!/bin/bash
# Create both S3 buckets for backend migration scenario

ENDPOINT="http://localhost:4566"

echo "Creating S3 buckets for Scenario 4: Backend Migration..."
echo ""

# Create Bucket A (source)
echo "Creating Bucket A (source)..."
aws s3 mb s3://tfstate-bucket-a --endpoint-url $ENDPOINT 2>/dev/null || echo "Bucket A already exists"
aws s3api put-bucket-versioning \
    --bucket tfstate-bucket-a \
    --versioning-configuration Status=Enabled \
    --endpoint-url $ENDPOINT

# Create Bucket B (target)
echo "Creating Bucket B (target)..."
aws s3 mb s3://tfstate-bucket-b --endpoint-url $ENDPOINT 2>/dev/null || echo "Bucket B already exists"
aws s3api put-bucket-versioning \
    --bucket tfstate-bucket-b \
    --versioning-configuration Status=Enabled \
    --endpoint-url $ENDPOINT

echo ""
echo "=========================================="
echo "Buckets created successfully!"
echo "=========================================="
echo ""
echo "Source bucket: s3://tfstate-bucket-a"
echo "Target bucket: s3://tfstate-bucket-b"
echo ""
echo "Next steps:"
echo "  1. terraform init     (uses backend-a.tf)"
echo "  2. terraform apply -auto-approve"
echo "  3. Verify state in bucket A:"
echo "     aws s3 ls s3://tfstate-bucket-a/ --recursive --endpoint-url $ENDPOINT"
echo ""
echo "  4. Rename backend-a.tf to backend-a.tf.bak"
echo "  5. Rename backend-b.tf.example to backend-b.tf"
echo "  6. terraform init -migrate-state"
echo "  7. Verify state moved to bucket B:"
echo "     aws s3 ls s3://tfstate-bucket-b/ --recursive --endpoint-url $ENDPOINT"
echo ""
