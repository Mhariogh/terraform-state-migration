# Scenario 3: Old Project (Source)
# =================================
# This project has grown too large.
# Your task: Move database resources to new-project.

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

  access_key = "test"
  secret_key = "test"

  endpoints {
    ec2 = "http://localhost:4566"
    rds = "http://localhost:4566"
    sts = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
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

# ============================================
# WEB RESOURCES (Keep in this project)
# ============================================

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"

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
    Name = "web-sg"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "web-server"
  }
}

# ============================================
# DATABASE RESOURCES (TODO: Move to new-project)
# ============================================
# After moving, comment out or remove these resources

resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Security group for database"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# Note: RDS not fully supported in LocalStack free tier
# Using a placeholder for demonstration
resource "aws_instance" "db" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.small"

  vpc_security_group_ids = [aws_security_group.db.id]

  tags = {
    Name = "db-server"
    Type = "database"
  }
}

# ============================================
# OUTPUTS
# ============================================

output "web_instance_id" {
  value = aws_instance.web.id
}

output "db_instance_id" {
  value = aws_instance.db.id
}

output "web_sg_id" {
  value = aws_security_group.web.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}
