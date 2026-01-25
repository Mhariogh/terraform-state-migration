#!/bin/bash
# ============================================================================
# Simulate a State File Disaster for Recovery Practice
# ============================================================================
#
# This script creates AWS resources then "loses" the state file,
# leaving you with orphaned resources to recover via terraform import.
#
# USAGE:
#   ./simulate-disaster.sh                    # Uses LocalStack (default)
#   ./simulate-disaster.sh localstack         # Explicitly use LocalStack
#   ./simulate-disaster.sh aws                # Use Real AWS
#
# ============================================================================

set -e

MODE="${1:-localstack}"

echo "=============================================="
echo "  SCENARIO 5: State Recovery Simulation"
echo "=============================================="
echo ""
echo "This script will:"
echo "  1. Create AWS resources (simulating existing infrastructure)"
echo "  2. 'Lose' the state file (simulating disaster)"
echo "  3. Leave you with orphaned resources to recover"
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
    echo "Finding latest Amazon Linux AMI..."
    AMI_ID=$(aws ec2 describe-images \
        --owners amazon \
        --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text \
        --region "$REGION")

    if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "None" ]; then
        AMI_ID=$(aws ec2 describe-images \
            --owners amazon \
            --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
            --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
            --output text \
            --region "$REGION")
    fi

    echo "Using AMI: $AMI_ID"
    echo ""

    # Get default VPC ID for security group
    VPC_ID=$(aws ec2 describe-vpcs \
        --filters "Name=is-default,Values=true" \
        --query 'Vpcs[0].VpcId' \
        --output text \
        --region "$REGION")

    # Get first availability zone
    AZ=$(aws ec2 describe-availability-zones \
        --region "$REGION" \
        --query 'AvailabilityZones[0].ZoneName' \
        --output text)

    echo "[Step 1/4] Creating EC2 instance..."
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "t2.micro" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=recovery-web-server},{Key=Environment,Value=production},{Key=Scenario,Value=5-state-recovery}]' \
        --region "$REGION" \
        --query 'Instances[0].InstanceId' \
        --output text)

    echo "   Instance ID: $INSTANCE_ID"

    echo "[Step 2/4] Creating Security Group..."
    # Delete if exists (cleanup from previous run)
    aws ec2 delete-security-group --group-name "recovery-web-sg" --region "$REGION" 2>/dev/null || true

    SG_ID=$(aws ec2 create-security-group \
        --group-name "recovery-web-sg" \
        --description "Security group for recovered web server" \
        --vpc-id "$VPC_ID" \
        --region "$REGION" \
        --query 'GroupId' \
        --output text)

    echo "   Security Group ID: $SG_ID"

    # Add ingress rules
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region "$REGION" 2>/dev/null || true

    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 \
        --region "$REGION" 2>/dev/null || true

    echo "[Step 3/4] Creating EBS Volume..."
    VOLUME_ID=$(aws ec2 create-volume \
        --availability-zone "$AZ" \
        --size 100 \
        --volume-type "gp3" \
        --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=recovery-data-volume},{Key=Environment,Value=production}]' \
        --region "$REGION" \
        --query 'VolumeId' \
        --output text)

    echo "   Volume ID: $VOLUME_ID"

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

    AMI_ID="ami-recovery-test"
    AZ="us-east-1a"

    echo "[Step 1/4] Creating EC2 instance..."
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "t2.micro" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=recovery-web-server},{Key=Environment,Value=production},{Key=Scenario,Value=5-state-recovery}]' \
        --endpoint-url "$ENDPOINT" \
        --query 'Instances[0].InstanceId' \
        --output text 2>/dev/null)

    echo "   Instance ID: $INSTANCE_ID"

    echo "[Step 2/4] Creating Security Group..."
    SG_ID=$(aws ec2 create-security-group \
        --group-name "recovery-web-sg" \
        --description "Security group for recovered web server" \
        --endpoint-url "$ENDPOINT" \
        --query 'GroupId' \
        --output text 2>/dev/null)

    echo "   Security Group ID: $SG_ID"

    # Add ingress rules
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --endpoint-url "$ENDPOINT" 2>/dev/null || true

    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 \
        --endpoint-url "$ENDPOINT" 2>/dev/null || true

    echo "[Step 3/4] Creating EBS Volume..."
    VOLUME_ID=$(aws ec2 create-volume \
        --availability-zone "$AZ" \
        --size 100 \
        --volume-type "gp3" \
        --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=recovery-data-volume},{Key=Environment,Value=production}]' \
        --endpoint-url "$ENDPOINT" \
        --query 'VolumeId' \
        --output text 2>/dev/null)

    echo "   Volume ID: $VOLUME_ID"
fi

echo "[Step 4/4] 'Losing' state file..."
rm -f terraform.tfstate terraform.tfstate.backup 2>/dev/null

echo ""
echo "=============================================="
echo "  DISASTER SIMULATED!"
echo "=============================================="
echo ""
echo "Resources exist in AWS but Terraform doesn't know about them."
echo ""
echo "Your task: Recover the state by importing these resources"
echo ""
echo "Resource IDs to import:"
echo "  aws_instance.web       -> $INSTANCE_ID"
echo "  aws_security_group.web -> $SG_ID"
echo "  aws_ebs_volume.data    -> $VOLUME_ID"
echo ""
echo "Commands to run:"
echo "  terraform init"
echo "  terraform import aws_instance.web $INSTANCE_ID"
echo "  terraform import aws_security_group.web $SG_ID"
echo "  terraform import aws_ebs_volume.data $VOLUME_ID"
echo "  terraform plan  # Should show 'No changes'"
echo ""

if [ "$MODE" = "aws" ]; then
    echo "NOTE: For Real AWS, use clean provider config (no LocalStack settings)."
    echo "      Update main.tf to match imported attributes (ami, vpc_security_group_ids, etc.)"
    echo ""
fi

# Save resource IDs for reference
cat > resource-ids.txt << EOF
# Resource IDs for State Recovery
# Use these IDs with terraform import

INSTANCE_ID=$INSTANCE_ID
SECURITY_GROUP_ID=$SG_ID
VOLUME_ID=$VOLUME_ID

# Import commands:
# terraform import aws_instance.web $INSTANCE_ID
# terraform import aws_security_group.web $SG_ID
# terraform import aws_ebs_volume.data $VOLUME_ID
EOF

echo "Resource IDs saved to: resource-ids.txt"
echo ""
