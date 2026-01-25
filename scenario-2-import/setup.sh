#!/bin/bash
# ============================================================================
# Setup Script - Create a "manually" created resource
# ============================================================================
#
# This simulates someone creating resources via AWS Console.
# The resource needs to be imported into Terraform.
#
# USAGE:
#   ./setup.sh                    # Uses LocalStack (default)
#   ./setup.sh localstack         # Explicitly use LocalStack
#   ./setup.sh aws                # Use Real AWS
#
# ============================================================================

set -e

MODE="${1:-localstack}"

echo "=============================================="
echo "  Create Resource for Import Scenario"
echo "=============================================="
echo ""

if [ "$MODE" = "aws" ]; then
    # ========================================
    # REAL AWS MODE
    # ========================================
    echo "Mode: REAL AWS"
    echo ""

    # Check AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        echo "X AWS credentials not configured!"
        echo ""
        echo "Run: aws configure"
        echo "Then try again."
        exit 1
    fi

    REGION="${AWS_DEFAULT_REGION:-us-east-1}"

    # Get latest Amazon Linux 2023 AMI
    echo "Finding latest Amazon Linux 2023 AMI..."
    AMI_ID=$(aws ec2 describe-images \
        --owners amazon \
        --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text \
        --region "$REGION")

    if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "None" ]; then
        echo "X Could not find AMI. Trying alternative..."
        AMI_ID=$(aws ec2 describe-images \
            --owners amazon \
            --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
            --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
            --output text \
            --region "$REGION")
    fi

    echo "Using AMI: $AMI_ID"
    echo ""

    # Create the instance
    echo "Creating EC2 instance 'manually' (simulating AWS Console)..."
    RESULT=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "t2.micro" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=manually-created-instance},{Key=CreatedBy,Value=console}]' \
        --region "$REGION" \
        --output json 2>&1)

    if [ $? -ne 0 ]; then
        echo ""
        echo "X Failed to create instance."
        echo "Error: $RESULT"
        exit 1
    fi

    INSTANCE_ID=$(echo "$RESULT" | grep -o '"InstanceId": "[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -z "$INSTANCE_ID" ]; then
        echo "X Could not extract instance ID."
        exit 1
    fi

    echo ""
    echo "=============================================="
    echo "  MANUALLY CREATED RESOURCE (Real AWS)"
    echo "=============================================="
    echo ""
    echo "Instance ID: $INSTANCE_ID"
    echo "AMI ID:      $AMI_ID"
    echo "Type:        t2.micro"
    echo "Region:      $REGION"
    echo ""
    echo "=============================================="
    echo ""
    echo "Your task:"
    echo "1. Add a resource block to main.tf:"
    echo ""
    echo "   resource \"aws_instance\" \"imported\" {"
    echo "     # Will be filled after import"
    echo "   }"
    echo ""
    echo "2. Run: terraform import aws_instance.imported $INSTANCE_ID"
    echo "3. Run: terraform state show aws_instance.imported"
    echo "4. Update main.tf to match (ami, instance_type, tags)"
    echo "5. Run: terraform plan (should show no changes)"
    echo ""
    echo "NOTE: For Real AWS, use clean provider config (no LocalStack settings)."
    echo ""

else
    # ========================================
    # LOCALSTACK MODE (Default)
    # ========================================
    echo "Mode: LOCALSTACK (Free)"
    echo ""

    ENDPOINT="http://localhost:4566"

    # Check if LocalStack is running
    if ! curl -s "$ENDPOINT/_localstack/health" &>/dev/null; then
        echo "X LocalStack not running!"
        echo ""
        echo "Start it with:"
        echo "  docker-compose up -d"
        echo ""
        echo "Then try again."
        exit 1
    fi

    echo "Creating EC2 instance 'manually' (simulating AWS Console)..."

    RESULT=$(aws ec2 run-instances \
        --image-id "ami-12345678" \
        --instance-type "t2.micro" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=manually-created-instance},{Key=CreatedBy,Value=console}]' \
        --endpoint-url "$ENDPOINT" \
        --output json 2>&1)

    if [ $? -ne 0 ]; then
        echo "X Could not create instance."
        echo "Error: $RESULT"
        exit 1
    fi

    INSTANCE_ID=$(echo "$RESULT" | grep -o '"InstanceId": "[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -z "$INSTANCE_ID" ]; then
        echo "X Could not extract instance ID."
        exit 1
    fi

    echo ""
    echo "=============================================="
    echo "  MANUALLY CREATED RESOURCE (LocalStack)"
    echo "=============================================="
    echo ""
    echo "Instance ID: $INSTANCE_ID"
    echo "AMI ID:      ami-12345678"
    echo "Type:        t2.micro"
    echo ""
    echo "=============================================="
    echo ""
    echo "Your task:"
    echo "1. Add a resource block to main.tf:"
    echo ""
    echo "   resource \"aws_instance\" \"imported\" {"
    echo "     # Will be filled after import"
    echo "   }"
    echo ""
    echo "2. Run: terraform import aws_instance.imported $INSTANCE_ID"
    echo "3. Run: terraform state show aws_instance.imported"
    echo "4. Update main.tf to match (ami, instance_type, tags)"
    echo "5. Run: terraform plan (should show no changes)"
    echo ""
fi

# Save instance ID for reference
echo "$INSTANCE_ID" > .instance_id
echo "Instance ID saved to .instance_id"
