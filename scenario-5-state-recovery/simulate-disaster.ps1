# Simulate a state file disaster for recovery practice (Windows PowerShell)

$ENDPOINT = "http://localhost:4566"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  SCENARIO 5: State Recovery Simulation" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will:"
Write-Host "  1. Create AWS resources (simulating existing infrastructure)"
Write-Host "  2. 'Lose' the state file (simulating disaster)"
Write-Host "  3. Leave you with orphaned resources to recover"
Write-Host ""

# Create resources directly via AWS CLI (simulating manual creation or lost state)
Write-Host "[Step 1/4] Creating EC2 instance..." -ForegroundColor Yellow
$INSTANCE_ID = aws ec2 run-instances `
    --image-id "ami-recovery-test" `
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
    --availability-zone "us-east-1a" `
    --size 100 `
    --volume-type "gp3" `
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=recovery-data-volume},{Key=Environment,Value=production}]' `
    --endpoint-url $ENDPOINT `
    --query 'VolumeId' `
    --output text 2>$null

Write-Host "   Volume ID: $VOLUME_ID"

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
