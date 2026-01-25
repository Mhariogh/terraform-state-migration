# Create both S3 buckets for backend migration scenario (Windows PowerShell)

$ENDPOINT = "http://localhost:4566"

Write-Host "Creating S3 buckets for Scenario 4: Backend Migration..." -ForegroundColor Cyan
Write-Host ""

# Create Bucket A (source)
Write-Host "Creating Bucket A (source)..." -ForegroundColor Yellow
aws s3 mb s3://tfstate-bucket-a --endpoint-url $ENDPOINT 2>$null
aws s3api put-bucket-versioning `
    --bucket tfstate-bucket-a `
    --versioning-configuration Status=Enabled `
    --endpoint-url $ENDPOINT

# Create Bucket B (target)
Write-Host "Creating Bucket B (target)..." -ForegroundColor Yellow
aws s3 mb s3://tfstate-bucket-b --endpoint-url $ENDPOINT 2>$null
aws s3api put-bucket-versioning `
    --bucket tfstate-bucket-b `
    --versioning-configuration Status=Enabled `
    --endpoint-url $ENDPOINT

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Buckets created successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Source bucket: s3://tfstate-bucket-a" -ForegroundColor White
Write-Host "Target bucket: s3://tfstate-bucket-b" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. terraform init     (uses backend-a.tf)"
Write-Host "  2. terraform apply -auto-approve"
Write-Host "  3. Verify state in bucket A:"
Write-Host "     aws s3 ls s3://tfstate-bucket-a/ --recursive --endpoint-url $ENDPOINT"
Write-Host ""
Write-Host "  4. Rename backend-a.tf to backend-a.tf.bak"
Write-Host "  5. Rename backend-b.tf.example to backend-b.tf"
Write-Host "  6. terraform init -migrate-state"
Write-Host "  7. Verify state moved to bucket B:"
Write-Host "     aws s3 ls s3://tfstate-bucket-b/ --recursive --endpoint-url $ENDPOINT"
Write-Host ""
