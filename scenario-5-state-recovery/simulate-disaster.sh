#!/bin/bash
# Simulate a state file disaster for recovery practice

ENDPOINT="http://localhost:4566"

echo "=============================================="
echo "  SCENARIO 5: State Recovery Simulation"
echo "=============================================="
echo ""
echo "This script will:"
echo "  1. Create AWS resources (simulating existing infrastructure)"
echo "  2. 'Lose' the state file (simulating disaster)"
echo "  3. Leave you with orphaned resources to recover"
echo ""

# Create resources directly via AWS CLI (simulating manual creation or lost state)
echo "[Step 1/4] Creating EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "ami-recovery-test" \
    --instance-type "t2.micro" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=recovery-web-server},{Key=Environment,Value=production},{Key=Scenario,Value=5-state-recovery}]' \
    --endpoint-url $ENDPOINT \
    --query 'Instances[0].InstanceId' \
    --output text 2>/dev/null)

echo "   Instance ID: $INSTANCE_ID"

echo "[Step 2/4] Creating Security Group..."
SG_ID=$(aws ec2 create-security-group \
    --group-name "recovery-web-sg" \
    --description "Security group for recovered web server" \
    --endpoint-url $ENDPOINT \
    --query 'GroupId' \
    --output text 2>/dev/null)

echo "   Security Group ID: $SG_ID"

# Add ingress rules
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --endpoint-url $ENDPOINT 2>/dev/null

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --endpoint-url $ENDPOINT 2>/dev/null

echo "[Step 3/4] Creating EBS Volume..."
VOLUME_ID=$(aws ec2 create-volume \
    --availability-zone "us-east-1a" \
    --size 100 \
    --volume-type "gp3" \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=recovery-data-volume},{Key=Environment,Value=production}]' \
    --endpoint-url $ENDPOINT \
    --query 'VolumeId' \
    --output text 2>/dev/null)

echo "   Volume ID: $VOLUME_ID"

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
echo "  aws_instance.web      -> $INSTANCE_ID"
echo "  aws_security_group.web -> $SG_ID"
echo "  aws_ebs_volume.data   -> $VOLUME_ID"
echo ""
echo "Commands to run:"
echo "  terraform init"
echo "  terraform import aws_instance.web $INSTANCE_ID"
echo "  terraform import aws_security_group.web $SG_ID"
echo "  terraform import aws_ebs_volume.data $VOLUME_ID"
echo "  terraform plan  # Should show 'No changes'"
echo ""

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
