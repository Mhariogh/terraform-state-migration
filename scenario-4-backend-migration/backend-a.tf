# Backend A Configuration
# This is the INITIAL backend - state starts here

terraform {
  backend "s3" {
    bucket = "tfstate-bucket-a"
    key    = "scenario-4/terraform.tfstate"
    region = "us-east-1"

    # LocalStack settings (remove for Real AWS)
    endpoints = {
      s3 = "http://localhost:4566"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    access_key                  = "test"
    secret_key                  = "test"
  }
}

# =====================================================
# INSTRUCTIONS:
# =====================================================
#
# Step 1: Start with THIS file (backend-a.tf)
#   - Run: terraform init
#   - Run: terraform apply -auto-approve
#   - Verify: aws s3 ls s3://tfstate-bucket-a/ --endpoint-url http://localhost:4566
#
# Step 2: Switch to backend-b.tf
#   - Rename this file: mv backend-a.tf backend-a.tf.bak
#   - Rename backend-b.tf.example: mv backend-b.tf.example backend-b.tf
#   - Run: terraform init -migrate-state
#   - Answer "yes" to migrate
#
# Step 3: Verify migration
#   - Run: terraform plan (should show "No changes")
#   - Check: aws s3 ls s3://tfstate-bucket-b/ --endpoint-url http://localhost:4566
#
# =====================================================
