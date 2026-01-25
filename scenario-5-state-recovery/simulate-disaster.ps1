# ============================================================================
# Simulate a State File Disaster for Recovery Practice (Windows PowerShell)
# ============================================================================
#
# This script creates AWS resources then "loses" the state file,
# leaving you with orphaned resources to recover via terraform import.
#
# USAGE:
#   .\simulate-disaster.ps1                    # Uses LocalStack (default)
#   .\simulate-disaster.ps1 localstack         # Explicitly use LocalStack
#   .\simulate-disaster.ps1 aws                # Use Real AWS
#
# ============================================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("localstack", "aws")]
    [string]$Mode = "localstack"
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  SCENARIO 5: State Recovery Simulation" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will:"
Write-Host "  1. Create AWS resources (simulating existing infrastructure)"
Write-Host "  2. 'Lose' the state file (simulating disaster)"
Write-Host "  3. Leave you with orphaned resources to recover"
Write-Host ""

if ($Mode -eq "aws") {
    # ========================================
    # REAL AWS MODE
    # ========================================
    Write-Host "Mode: REAL AWS" -ForegroundColor Yellow
    Write-Host ""

    # Check AWS credentials
    try {
        $identity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
        if (-not $identity) { throw "No credentials" }
    }
    catch {
        Write-Host "X AWS credentials not configured!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Run: aws configure"
        Write-Host "Then try again."
        exit 1
    }

    $REGION = if ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } else { "us-east-1" }

    # Get latest Amazon Linux 2023 AMI
    Write-Host "Finding latest Amazon Linux AMI..." -ForegroundColor Yellow
    $AMI_ID = aws ec2 describe-images `
        --owners amazon `
        --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' `
        --output text `
        --region $REGION

    if (-not $AMI_ID -or $AMI_ID -eq "None") {
        $AMI_ID = aws ec2 describe-images `
            --owners amazon `
            --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" `
            --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' `
            --output text `
            --region $REGION
    }

    Write-Host "Using AMI: $AMI_ID"
    Write-Host ""

    # Get default VPC ID
    $VPC_ID = aws ec2 describe-vpcs `
        --filters "Name=is-default,Values=true" `
        --query 'Vpcs[0].VpcId' `
        --output text `
        --region $REGION

    # Get first availability zone
    $AZ = aws ec2 describe-availability-zones `
        --region $REGION `
        --query 'AvailabilityZones[0].ZoneName' `
        --output text

    Write-Host "[Step 1/4] Creating EC2 instance..." -ForegroundColor Yellow
    $INSTANCE_ID = aws ec2 run-instances `
        --image-id $AMI_ID `
        --instance-type "t2.micro" `
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=recovery-web-server},{Key=Environment,Value=production},{Key=Scenario,Value=5-state-recovery}]' `
        --region $REGION `
        --query 'Instances[0].InstanceId' `
        --output text

    Write-Host "   Instance ID: $INSTANCE_ID"

    Write-Host "[Step 2/4] Creating Security Group..." -ForegroundColor Yellow
    # Delete if exists (cleanup from previous run)
    aws ec2 delete-security-group --group-name "recovery-web-sg" --region $REGION 2>$null

    $SG_ID = aws ec2 create-security-group `
        --group-name "recovery-web-sg" `
        --description "Security group for recovered web server" `
        --vpc-id $VPC_ID `
        --region $REGION `
        --query 'GroupId' `
        --output text

    Write-Host "   Security Group ID: $SG_ID"

    # Add ingress rules
    aws ec2 authorize-security-group-ingress `
        --group-id $SG_ID `
        --protocol tcp `
        --port 80 `
        --cidr 0.0.0.0/0 `
        --region $REGION 2>$null | Out-Null

    aws ec2 authorize-security-group-ingress `
        --group-id $SG_ID `
        --protocol tcp `
        --port 443 `
        --cidr 0.0.0.0/0 `
        --region $REGION 2>$null | Out-Null

    Write-Host "[Step 3/4] Creating EBS Volume..." -ForegroundColor Yellow
    $VOLUME_ID = aws ec2 create-volume `
        --availability-zone $AZ `
        --size 100 `
        --volume-type "gp3" `
        --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=recovery-data-volume},{Key=Environment,Value=production}]' `
        --region $REGION `
        --query 'VolumeId' `
        --output text

    Write-Host "   Volume ID: $VOLUME_ID"
}
else {
    # ========================================
    # LOCALSTACK MODE (Default)
    # ========================================
    Write-Host "Mode: LOCALSTACK (Free)" -ForegroundColor Yellow
    Write-Host ""

    $ENDPOINT = "http://localhost:4566"

    # Check if LocalStack is running
    try {
        $health = Invoke-RestMethod -Uri "$ENDPOINT/_localstack/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "X LocalStack not running!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Start it with:"
        Write-Host "  docker-compose up -d"
        Write-Host ""
        Write-Host "Then try again."
        exit 1
    }

    $AMI_ID = "ami-recovery-test"
    $AZ = "us-east-1a"

    Write-Host "[Step 1/4] Creating EC2 instance..." -ForegroundColor Yellow
    $INSTANCE_ID = aws ec2 run-instances `
        --image-id $AMI_ID `
        --instance-type "t2.micro" `
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=recovery-web-server},{Key=Environment,Value=production},{Key=Scenario,Value=5-state-recovery}]' `
        --endpoint-url $ENDPOINT `
        --query 'Instances[0].InstanceId' `
        --output text 2>$null

    Write-Host "   Instance ID: $INSTANCE_ID"

    Write-Host "[Step 2/4] Creating Security Group..." -ForegroundColor Yellow
    $SG_ID = aws ec2 create-security-group `
        --group-name "recovery-web-sg" `
        --description "Security group for recovered web server" `
        --endpoint-url $ENDPOINT `
        --query 'GroupId' `
        --output text 2>$null

    Write-Host "   Security Group ID: $SG_ID"

    # Add ingress rules
    aws ec2 authorize-security-group-ingress `
        --group-id $SG_ID `
        --protocol tcp `
        --port 80 `
        --cidr 0.0.0.0/0 `
        --endpoint-url $ENDPOINT 2>$null | Out-Null

    aws ec2 authorize-security-group-ingress `
        --group-id $SG_ID `
        --protocol tcp `
        --port 443 `
        --cidr 0.0.0.0/0 `
        --endpoint-url $ENDPOINT 2>$null | Out-Null

    Write-Host "[Step 3/4] Creating EBS Volume..." -ForegroundColor Yellow
    $VOLUME_ID = aws ec2 create-volume `
        --availability-zone $AZ `
        --size 100 `
        --volume-type "gp3" `
        --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=recovery-data-volume},{Key=Environment,Value=production}]' `
        --endpoint-url $ENDPOINT `
        --query 'VolumeId' `
        --output text 2>$null

    Write-Host "   Volume ID: $VOLUME_ID"
}

Write-Host "[Step 4/4] 'Losing' state file..." -ForegroundColor Yellow
Remove-Item -Path "terraform.tfstate", "terraform.tfstate.backup" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==============================================" -ForegroundColor Red
Write-Host "  DISASTER SIMULATED!" -ForegroundColor Red
Write-Host "==============================================" -ForegroundColor Red
Write-Host ""
Write-Host "Resources exist in AWS but Terraform doesn't know about them."
Write-Host ""
Write-Host "Your task: Recover the state by importing these resources" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resource IDs to import:" -ForegroundColor White
Write-Host "  aws_instance.web       -> $INSTANCE_ID"
Write-Host "  aws_security_group.web -> $SG_ID"
Write-Host "  aws_ebs_volume.data    -> $VOLUME_ID"
Write-Host ""
Write-Host "Commands to run:" -ForegroundColor Green
Write-Host "  terraform init"
Write-Host "  terraform import aws_instance.web $INSTANCE_ID"
Write-Host "  terraform import aws_security_group.web $SG_ID"
Write-Host "  terraform import aws_ebs_volume.data $VOLUME_ID"
Write-Host "  terraform plan  # Should show 'No changes'"
Write-Host ""

if ($Mode -eq "aws") {
    Write-Host "NOTE: For Real AWS, use clean provider config (no LocalStack settings)." -ForegroundColor Yellow
    Write-Host "      Update main.tf to match imported attributes (ami, vpc_security_group_ids, etc.)"
    Write-Host ""
}

# Save resource IDs for reference
@"
# Resource IDs for State Recovery
# Use these IDs with terraform import

INSTANCE_ID=$INSTANCE_ID
SECURITY_GROUP_ID=$SG_ID
VOLUME_ID=$VOLUME_ID

# Import commands:
# terraform import aws_instance.web $INSTANCE_ID
# terraform import aws_security_group.web $SG_ID
# terraform import aws_ebs_volume.data $VOLUME_ID
"@ | Out-File -FilePath "resource-ids.txt" -Encoding UTF8

Write-Host "Resource IDs saved to: resource-ids.txt" -ForegroundColor Green
Write-Host ""
