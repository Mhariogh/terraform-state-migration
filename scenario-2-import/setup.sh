#!/bin/bash
# Setup Script - Create a "manually" created resource
# ====================================================
# This simulates someone creating resources via AWS Console

ENDPOINT="http://localhost:4566"

echo "Creating EC2 instance 'manually' (simulating AWS Console)..."

# Get AMI ID
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text \
  --endpoint-url $ENDPOINT 2>/dev/null || echo "ami-12345678")

# Create the instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=manually-created-instance},{Key=CreatedBy,Value=console}]" \
  --query 'Instances[0].InstanceId' \
  --output text \
  --endpoint-url $ENDPOINT 2>/dev/null)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  # Fallback for LocalStack
  INSTANCE_ID="i-$(date +%s)"
  echo "LocalStack mode: Using simulated instance ID"
fi

echo ""
echo "=========================================="
echo "  MANUALLY CREATED RESOURCE"
echo "=========================================="
echo ""
echo "Instance ID: $INSTANCE_ID"
echo "AMI ID:      $AMI_ID"
echo "Type:        t2.micro"
echo ""
echo "=========================================="
echo ""
echo "Your task:"
echo "1. Write a resource block in main.tf for this instance"
echo "2. Run: terraform import aws_instance.imported $INSTANCE_ID"
echo "3. Run: terraform state show aws_instance.imported"
echo "4. Update main.tf to match the imported state"
echo "5. Run: terraform plan (should show no changes)"
echo ""

# Save instance ID for reference
echo "$INSTANCE_ID" > .instance_id
