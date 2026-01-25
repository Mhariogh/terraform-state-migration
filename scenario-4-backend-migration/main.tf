# Scenario 4: Backend Migration
# Migrate state from one S3 bucket to another

# =====================================================
# TASK: Migrate state from bucket-a to bucket-b
# =====================================================
#
# This simulates a common real-world scenario:
# - Company restructuring storage
# - Moving to a different region
# - Consolidating state files
# - Changing naming conventions
#
# Steps:
# 1. Run create-buckets.sh to create both S3 buckets
# 2. terraform init (uses backend-a.tf - bucket A)
# 3. terraform apply (creates resources, state in bucket A)
# 4. Verify state is in bucket A
# 5. Switch to backend-b.tf configuration
# 6. terraform init -migrate-state (moves state to bucket B)
# 7. Verify state is now in bucket B
# 8. Verify: terraform plan shows "No changes"
#
# =====================================================

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# LocalStack provider configuration
# For Real AWS: Remove the endpoints, skip_* settings, and use real credentials
provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# Simple resources to track in state
resource "aws_instance" "app" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name        = "backend-migration-demo"
    Environment = "learning"
    Scenario    = "4-backend-migration"
  }
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Security group for backend migration demo"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}

output "instance_id" {
  value = aws_instance.app.id
}

output "security_group_id" {
  value = aws_security_group.app.id
}
