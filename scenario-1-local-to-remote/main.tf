# Scenario 1: Local to Remote State Migration
# ============================================
# This project currently uses local state.
# Your task: Migrate it to S3 remote state.

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider - LocalStack
provider "aws" {
  region = "us-east-1"

  # LocalStack configuration (remove for real AWS)
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
  s3_use_path_style           = true
}

# Data source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group
resource "aws_security_group" "web" {
  name        = "web-sg-migration-demo"
  description = "Security group for migration demo"

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name    = "web-sg-migration-demo"
    Project = "state-migration"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name    = "web-server-migration-demo"
    Project = "state-migration"
  }
}

# Outputs
output "instance_id" {
  value = aws_instance.web.id
}

output "security_group_id" {
  value = aws_security_group.web.id
}
