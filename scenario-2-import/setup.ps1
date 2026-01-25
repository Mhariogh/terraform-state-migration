# ============================================================================
# Setup Script - Create a "manually" created resource (Windows PowerShell)
# ============================================================================
#
# This simulates someone creating resources via AWS Console.
# The resource needs to be imported into Terraform.
#
# USAGE:
#   .\setup.ps1                    # Uses LocalStack (default)
#   .\setup.ps1 localstack         # Explicitly use LocalStack
#   .\setup.ps1 aws                # Use Real AWS
#
# ============================================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("localstack", "aws")]
    [string]$Mode = "localstack"
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Create Resource for Import Scenario" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
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
    Write-Host "Finding latest Amazon Linux 2023 AMI..." -ForegroundColor Yellow
    $AMI_ID = aws ec2 describe-images `
        --owners amazon `
        --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' `
        --output text `
        --region $REGION

    if (-not $AMI_ID -or $AMI_ID -eq "None") {
        Write-Host "Trying alternative AMI..." -ForegroundColor Yellow
        $AMI_ID = aws ec2 describe-images `
            --owners amazon `
            --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" `
            --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' `
            --output text `
            --region $REGION
    }

    Write-Host "Using AMI: $AMI_ID"
    Write-Host ""

    # Create the instance
    Write-Host "Creating EC2 instance 'manually' (simulating AWS Console)..." -ForegroundColor Yellow
    try {
        $result = aws ec2 run-instances `
            --image-id $AMI_ID `
            --instance-type "t2.micro" `
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=manually-created-instance},{Key=CreatedBy,Value=console}]" `
            --region $REGION `
            --output json | ConvertFrom-Json

        $INSTANCE_ID = $result.Instances[0].InstanceId
    }
    catch {
        Write-Host ""
        Write-Host "X Failed to create instance." -ForegroundColor Red
        Write-Host $_.Exception.Message
        exit 1
    }

    if (-not $INSTANCE_ID) {
        Write-Host "X Could not extract instance ID." -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "  MANUALLY CREATED RESOURCE (Real AWS)" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Instance ID: $INSTANCE_ID" -ForegroundColor Yellow
    Write-Host "AMI ID:      $AMI_ID"
    Write-Host "Type:        t2.micro"
    Write-Host "Region:      $REGION"
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your task:" -ForegroundColor Cyan
    Write-Host "1. Add a resource block to main.tf:"
    Write-Host ""
    Write-Host "   resource `"aws_instance`" `"imported`" {"
    Write-Host "     # Will be filled after import"
    Write-Host "   }"
    Write-Host ""
    Write-Host "2. Run: terraform import aws_instance.imported $INSTANCE_ID"
    Write-Host "3. Run: terraform state show aws_instance.imported"
    Write-Host "4. Update main.tf to match (ami, instance_type, tags)"
    Write-Host "5. Run: terraform plan (should show no changes)"
    Write-Host ""
    Write-Host "NOTE: For Real AWS, use clean provider config (no LocalStack settings)." -ForegroundColor Yellow
    Write-Host ""
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

    Write-Host "Creating EC2 instance 'manually' (simulating AWS Console)..." -ForegroundColor Yellow

    $result = aws ec2 run-instances `
        --image-id "ami-12345678" `
        --instance-type "t2.micro" `
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=manually-created-instance},{Key=CreatedBy,Value=console}]" `
        --endpoint-url $ENDPOINT `
        --output json | ConvertFrom-Json

    $INSTANCE_ID = $result.Instances[0].InstanceId

    if (-not $INSTANCE_ID) {
        Write-Host "X Could not create instance." -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "  MANUALLY CREATED RESOURCE (LocalStack)" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Instance ID: $INSTANCE_ID" -ForegroundColor Yellow
    Write-Host "AMI ID:      ami-12345678"
    Write-Host "Type:        t2.micro"
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your task:" -ForegroundColor Cyan
    Write-Host "1. Add a resource block to main.tf:"
    Write-Host ""
    Write-Host "   resource `"aws_instance`" `"imported`" {"
    Write-Host "     # Will be filled after import"
    Write-Host "   }"
    Write-Host ""
    Write-Host "2. Run: terraform import aws_instance.imported $INSTANCE_ID"
    Write-Host "3. Run: terraform state show aws_instance.imported"
    Write-Host "4. Update main.tf to match (ami, instance_type, tags)"
    Write-Host "5. Run: terraform plan (should show no changes)"
    Write-Host ""
}

# Save instance ID for reference
$INSTANCE_ID | Out-File -FilePath ".instance_id" -NoNewline
Write-Host "Instance ID saved to .instance_id"
