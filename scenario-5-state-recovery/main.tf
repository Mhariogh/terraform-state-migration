# Scenario 5: State Recovery
# Recover from lost or corrupted state file

# =====================================================
# TASK: Rebuild state from existing resources
# =====================================================
#
# This simulates a disaster recovery scenario:
# - State file was accidentally deleted
# - State file became corrupted
# - State was lost during migration
# - Need to "adopt" orphaned resources
#
# Steps:
# 1. Run simulate-disaster.sh to create resources and "lose" state
# 2. terraform init
# 3. terraform plan shows it wants to CREATE resources
#    (but they already exist!)
# 4. Import each existing resource:
#    terraform import aws_instance.web <INSTANCE_ID>
#    terraform import aws_security_group.web <SG_ID>
# 5. terraform plan shows "No changes" (state recovered!)
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

# =====================================================
# Resources to recover
# These definitions must match the existing resources
# =====================================================

resource "aws_instance" "web" {
  ami           = "ami-recovery-test"
  instance_type = "t2.micro"

  tags = {
    Name        = "recovery-web-server"
    Environment = "production"
    Scenario    = "5-state-recovery"
  }
}

resource "aws_security_group" "web" {
  name        = "recovery-web-sg"
  description = "Security group for recovered web server"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    Name = "recovery-web-sg"
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"

  tags = {
    Name        = "recovery-data-volume"
    Environment = "production"
  }
}

output "instance_id" {
  description = "ID of the recovered web instance"
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "ID of the recovered security group"
  value       = aws_security_group.web.id
}

output "volume_id" {
  description = "ID of the recovered EBS volume"
  value       = aws_ebs_volume.data.id
}
