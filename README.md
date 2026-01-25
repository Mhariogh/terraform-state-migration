# Terraform State Migration Challenge

Master the art of Terraform state management, migration, and disaster recovery.

---

## What You'll Learn

- Understand Terraform state structure and purpose
- Migrate state from local to remote (S3) backend
- Import existing AWS resources into Terraform
- Move resources between state files
- Backup and recover state files

---

## Getting Started

### Step 1: Get the Code

Choose ONE of these options:

```
┌─────────────────────────────────────────────────────────────────┐
│                    HOW TO GET THE CODE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  OPTION A: FORK (Recommended)                                   │
│  ────────────────────────────                                   │
│  ✅ You get your own copy on GitHub                             │
│  ✅ You can push your changes                                   │
│  ✅ GitHub Actions auto-grades your work                        │
│  ✅ Shows on your GitHub profile                                │
│                                                                 │
│  OPTION B: CLONE ONLY                                           │
│  ─────────────────────                                          │
│  ✅ Quick start, no GitHub account needed                       │
│  ✅ Local grading with python run.py                            │
│  ❌ Cannot push changes to GitHub                               │
│  ❌ No automated GitHub Actions grading                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Option A: Fork (Recommended for Full Experience)

Forking creates YOUR OWN copy of this repository on GitHub.

```bash
# 1. Click the "Fork" button at the top-right of this page
#    This creates: github.com/YOUR-USERNAME/terraform-state-migration

# 2. Clone YOUR fork (not the original!)
git clone https://github.com/YOUR-USERNAME/terraform-state-migration.git
cd terraform-state-migration

# 3. When you complete the challenge, push to YOUR fork
git add .
git commit -m "Complete terraform-state-migration challenge"
git push origin main

# 4. GitHub Actions will automatically grade your work!
#    Check the "Actions" tab in your forked repo
```

**Why Fork?**
- You own the copy - can modify freely
- Push triggers GitHub Actions grading
- Builds your GitHub portfolio
- Can reference in job applications

#### Option B: Clone Only (Quick Start)

Just want to practice locally? Clone directly:

```bash
# Clone the original repo
git clone https://github.com/techlearn-center/terraform-state-migration.git
cd terraform-state-migration

# Complete the challenge...

# Grade locally (no GitHub needed)
python run.py --verify
```

**Note:** You cannot push to `techlearn-center` repo (you don't have permission).
To save your work on GitHub, you'll need to create your own repo:

```bash
# Create a new repo on github.com/new, then:
git remote remove origin
git remote add origin https://github.com/YOUR-USERNAME/YOUR-NEW-REPO.git
git push -u origin main
```

### Step 2: Choose Your Infrastructure Path

| Path | Cost | Best For |
|------|------|----------|
| 🐳 **LocalStack** | FREE | Learning, practice |
| ☁️ **Real AWS** | ~$1-5 | Production experience |

See detailed instructions for each path below.

---

## What is Terraform State?

### The Problem State Solves

When you run `terraform apply`, Terraform needs to know:
1. What resources exist in the real world?
2. What resources are defined in your code?
3. What's the difference (what to create/update/delete)?

**Terraform State** is the answer - it's a JSON file that maps your configuration to real-world resources.

```
┌─────────────────────────────────────────────────────────────────┐
│                    HOW TERRAFORM STATE WORKS                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Your Code (main.tf)          Terraform State           AWS   │
│   ─────────────────────        ───────────────        ─────── │
│                                                                 │
│   resource "aws_instance"  ──► "aws_instance.web" ──► i-abc123 │
│     name = "web"               id = "i-abc123"         (real)  │
│     type = "t2.micro"          type = "t2.micro"               │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  terraform plan                                          │  │
│   │  ─────────────────                                       │  │
│   │  Compares: Code ↔ State ↔ Real World                    │  │
│   │  Result: "No changes" or list of changes needed         │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### What's Inside a State File?

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 42,
  "lineage": "abc123-def456-...",
  "outputs": {
    "instance_ip": {
      "value": "54.123.45.67",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-0abc123def456",
            "ami": "ami-12345678",
            "instance_type": "t2.micro"
          }
        }
      ]
    }
  ]
}
```

### State File Components Explained

| Component | Purpose | Example |
|-----------|---------|---------|
| `version` | State format version | `4` (current) |
| `terraform_version` | Terraform version that wrote state | `1.5.0` |
| `serial` | Increments on every change | `42` |
| `lineage` | Unique ID for this state (never changes) | `abc123-def456` |
| `outputs` | Output values from configuration | `instance_ip = "54.123.45.67"` |
| `resources` | All managed resources and their attributes | `aws_instance.web` |

---

## Why State Migration?

### Real-World Scenarios

```
┌─────────────────────────────────────────────────────────────────┐
│                 WHEN YOU NEED STATE MIGRATION                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📁 Scenario 1: Local to Remote                                 │
│  ───────────────────────────────                                │
│  You started with local state on your laptop.                   │
│  Now the team needs to collaborate.                             │
│  → Migrate to S3 backend with state locking                     │
│                                                                 │
│  🏢 Scenario 2: Import Existing Resources                       │
│  ──────────────────────────────────────────                     │
│  Someone created resources manually in AWS Console.             │
│  Now you need Terraform to manage them.                         │
│  → Import into Terraform state                                  │
│                                                                 │
│  🔀 Scenario 3: Splitting Configurations                        │
│  ────────────────────────────────────────                       │
│  Your Terraform grew too large (500+ resources).                │
│  Need to split into modules or separate states.                 │
│  → Move resources between state files                           │
│                                                                 │
│  🔄 Scenario 4: Backend Migration                               │
│  ─────────────────────────────────                              │
│  Company switching from Terraform Cloud to S3.                  │
│  Or from one S3 bucket to another.                              │
│  → Migrate between backends                                     │
│                                                                 │
│  🆘 Scenario 5: State Recovery                                  │
│  ─────────────────────────────                                  │
│  State file corrupted or accidentally deleted.                  │
│  Need to rebuild state from existing resources.                 │
│  → Import and reconstruct state                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### The Cost of Getting It Wrong

```
┌─────────────────────────────────────────────────────────────────┐
│                    ⚠️ STATE MIGRATION RISKS                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ❌ WRONG: terraform destroy + terraform apply                  │
│     • Destroys production resources!                            │
│     • Causes downtime                                           │
│     • May lose data permanently                                 │
│                                                                 │
│  ❌ WRONG: Manually editing state file                          │
│     • Corrupts state                                            │
│     • Creates drift between state and reality                   │
│     • Breaks future operations                                  │
│                                                                 │
│  ✅ RIGHT: Use Terraform state commands                         │
│     • terraform state mv    (move/rename resources)             │
│     • terraform state rm    (remove from state)                 │
│     • terraform import      (add existing resource)             │
│     • terraform init -migrate-state (change backend)            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Essential State Commands

### Command Reference

```bash
# ═══════════════════════════════════════════════════════════════
# LISTING & VIEWING
# ═══════════════════════════════════════════════════════════════

# List all resources in state
terraform state list
# Output:
# aws_instance.web
# aws_security_group.main

# Show details of a specific resource
terraform state show aws_instance.web
# Output: Full resource configuration

# ═══════════════════════════════════════════════════════════════
# MOVING & RENAMING
# ═══════════════════════════════════════════════════════════════

# Rename a resource (within same state)
terraform state mv aws_instance.web aws_instance.web_server

# Move resource to different state file
terraform state mv -state-out=other/terraform.tfstate \
  aws_instance.db aws_instance.db

# ═══════════════════════════════════════════════════════════════
# REMOVING (Resource still exists in AWS!)
# ═══════════════════════════════════════════════════════════════

# Remove from state - Terraform forgets it, but it still exists
terraform state rm aws_instance.web

# ═══════════════════════════════════════════════════════════════
# IMPORTING EXISTING RESOURCES
# ═══════════════════════════════════════════════════════════════

# Import existing AWS resource into Terraform
terraform import aws_instance.web i-0abc123def456

# ═══════════════════════════════════════════════════════════════
# BACKEND MIGRATION
# ═══════════════════════════════════════════════════════════════

# Migrate state to new backend (e.g., local → S3)
terraform init -migrate-state

# Reconfigure backend without migrating
terraform init -reconfigure

# ═══════════════════════════════════════════════════════════════
# BACKUP & RECOVERY
# ═══════════════════════════════════════════════════════════════

# Download remote state to local file
terraform state pull > backup.json

# Upload local state to remote (DANGEROUS - use carefully!)
terraform state push backup.json
```

### Migration Workflow: Local to S3

```
┌─────────────────────────────────────────────────────────────────┐
│              LOCAL TO REMOTE MIGRATION WORKFLOW                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Backup current state                                   │
│  ────────────────────────────                                   │
│  $ cp terraform.tfstate terraform.tfstate.backup                │
│                                                                 │
│  Step 2: Create remote backend (S3 bucket)                      │
│  ────────────────────────────────────────────                   │
│  $ aws s3 mb s3://my-terraform-state-bucket                     │
│                                                                 │
│  Step 3: Add backend configuration                              │
│  ───────────────────────────────────                            │
│  # backend.tf                                                   │
│  terraform {                                                    │
│    backend "s3" {                                               │
│      bucket = "my-terraform-state-bucket"                       │
│      key    = "prod/terraform.tfstate"                          │
│      region = "us-east-1"                                       │
│    }                                                            │
│  }                                                              │
│                                                                 │
│  Step 4: Initialize with migration                              │
│  ────────────────────────────────────                           │
│  $ terraform init -migrate-state                                │
│                                                                 │
│  Terraform asks: "Copy existing state to new backend?"          │
│  Answer: yes                                                    │
│                                                                 │
│  Step 5: Verify migration                                       │
│  ─────────────────────────                                      │
│  $ terraform plan  # Should show "No changes"                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Import Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      IMPORT WORKFLOW                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Write empty resource block                             │
│  ────────────────────────────────────                           │
│  # main.tf                                                      │
│  resource "aws_instance" "imported" {                           │
│    # Leave empty for now                                        │
│  }                                                              │
│                                                                 │
│  Step 2: Import the resource                                    │
│  ─────────────────────────────                                  │
│  $ terraform import aws_instance.imported i-0abc123def456       │
│                                                                 │
│  Step 3: View imported attributes                               │
│  ──────────────────────────────────                             │
│  $ terraform state show aws_instance.imported                   │
│                                                                 │
│  Step 4: Copy attributes to your code                           │
│  ─────────────────────────────────────                          │
│  resource "aws_instance" "imported" {                           │
│    ami           = "ami-12345678"    # From state show          │
│    instance_type = "t2.micro"        # From state show          │
│  }                                                              │
│                                                                 │
│  Step 5: Verify                                                 │
│  ─────────────                                                  │
│  $ terraform plan  # Should show "No changes"                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Choose Your Path

> **Pick ONE path and stick with it for the entire challenge.**

| Path | Cost | Best For | Requirements |
|------|------|----------|--------------|
| 🐳 **LocalStack** | FREE | Learning, practice | Docker, Terraform |
| ☁️ **Real AWS** | ~$1-5 | Production experience | AWS account, Terraform |

---

# 🐳 LOCALSTACK PATH (Free, Recommended for Learning)

<details open>
<summary><b>Click to expand LocalStack instructions</b></summary>

## LocalStack Setup

### Prerequisites
- Docker Desktop installed and running
- Terraform CLI installed
- Python 3 (for grading script)
- Code downloaded (see [Getting Started](#getting-started) above)

### Step 1: Start LocalStack

```bash
# Navigate to your cloned/forked repo
cd terraform-state-migration

# Start LocalStack
docker-compose up -d

# Verify LocalStack is running
docker-compose ps
# Should show "localstack" container as "Up"
```

### Step 2: Complete the Scenarios

#### Scenario 1: Local to Remote State Migration

```bash
cd scenario-1-local-to-remote

# Create the S3 bucket in LocalStack
chmod +x create-bucket.sh
./create-bucket.sh

# Initialize with LOCAL state first
# (backend.tf should have S3 backend COMMENTED OUT)
terraform init
terraform apply -auto-approve

# Verify resources created
terraform state list
# Should show: aws_instance.web, aws_security_group.web

# Now uncomment the S3 backend in backend.tf
# Then migrate state to S3
terraform init -migrate-state
# Answer "yes" when prompted

# Verify migration succeeded
terraform plan
# Should show: "No changes"
```

#### Scenario 2: Import Existing Resources

```bash
cd ../scenario-2-import

# Create a resource "manually" (simulating AWS Console)
chmod +x setup.sh
./setup.sh
# Note the Instance ID from output!

# Initialize Terraform
terraform init

# Add resource block to main.tf (if not already there)
# resource "aws_instance" "imported" { }

# Import the existing resource
terraform import aws_instance.imported <INSTANCE_ID>

# View imported attributes
terraform state show aws_instance.imported

# Update main.tf to match the imported state
# Then verify
terraform plan
# Should show: "No changes"
```

#### Scenario 3: Move Resources Between States

```bash
cd ../scenario-3-move/old-project

# Create resources in old project
terraform init
terraform apply -auto-approve
terraform state list
# Shows: aws_instance.web, aws_instance.db, etc.

# Initialize new project
cd ../new-project
terraform init

# Go back and move database resources
cd ../old-project
terraform state mv -state-out=../new-project/terraform.tfstate \
  aws_instance.db aws_instance.db

# Verify both projects
terraform state list  # old-project: web only
cd ../new-project
terraform state list  # new-project: db only
```

### Step 3: Verify Your Work

```bash
cd ..  # Back to project root

# Run the grading script
python run.py --verify --mode localstack
```

### Step 4: Submit

```bash
git add .
git commit -m "Complete terraform-state-migration challenge"
git push origin main
# Check GitHub Actions for automated grading
```

</details>

---

# ☁️ REAL AWS PATH (Production Experience)

<details>
<summary><b>Click to expand Real AWS instructions</b></summary>

## Real AWS Setup

### Prerequisites
- AWS Account ([Sign up free](https://aws.amazon.com/free/))
- AWS CLI installed and configured
- Terraform CLI installed
- Python 3 (for grading script)
- Code downloaded (see [Getting Started](#getting-started) above)

### Step 1: Configure AWS

```bash
# Configure AWS CLI
aws configure
# Enter:
#   AWS Access Key ID: (from IAM console)
#   AWS Secret Access Key: (from IAM console)
#   Default region: us-east-1
#   Default output format: json

# Verify configuration
aws sts get-caller-identity
# Should show your account ID
```

### Step 2: Modify Provider Configurations

**IMPORTANT:** You must update the provider blocks in ALL scenario main.tf files.

For each scenario, find and **REPLACE** the LocalStack provider:

```hcl
# DELETE THIS (LocalStack config):
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

# REPLACE WITH THIS (Real AWS):
provider "aws" {
  region = "us-east-1"
}
```

### Step 3: Complete the Scenarios

#### Scenario 1: Local to Remote State Migration

```bash
cd scenario-1-local-to-remote

# Create S3 bucket for state (use your account ID for uniqueness)
export STATE_BUCKET="tfstate-$(aws sts get-caller-identity --query Account --output text)"
aws s3 mb s3://$STATE_BUCKET --region us-east-1
aws s3api put-bucket-versioning --bucket $STATE_BUCKET --versioning-configuration Status=Enabled
echo "Your bucket: $STATE_BUCKET"

# Update backend.tf with YOUR bucket name
# Replace: bucket = "your-bucket-name"
# With:    bucket = "tfstate-123456789012"  (your actual bucket)

# Remove LocalStack-specific settings from backend.tf:
# DELETE these lines:
#   endpoints = { s3 = "http://localhost:4566" }
#   skip_credentials_validation = true
#   skip_metadata_api_check     = true
#   skip_requesting_account_id  = true
#   use_path_style              = true
#   access_key                  = "test"
#   secret_key                  = "test"

# Initialize with local state first (backend commented out)
terraform init
terraform apply -auto-approve

# Verify resources created
terraform state list

# Uncomment the S3 backend in backend.tf
# Then migrate
terraform init -migrate-state
# Answer "yes"

# Verify
terraform plan
# Should show: "No changes"

# COLLECT EVIDENCE (Important!)
mkdir -p ../evidence
terraform plan -no-color > ../evidence/scenario1-plan.txt
terraform state list > ../evidence/scenario1-state.txt
aws s3 ls s3://$STATE_BUCKET/ --recursive > ../evidence/s3-state-proof.txt
```

#### Scenario 2: Import Existing Resources

```bash
cd ../scenario-2-import

# Create an EC2 instance manually via AWS Console or CLI
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text)

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=manually-created}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"
# SAVE THIS ID!

# Initialize Terraform
terraform init

# Add to main.tf:
# resource "aws_instance" "imported" { }

# Import
terraform import aws_instance.imported $INSTANCE_ID

# View attributes
terraform state show aws_instance.imported

# Update main.tf with the correct ami and instance_type
# Then verify
terraform plan
# Should show: "No changes"

# COLLECT EVIDENCE
terraform plan -no-color > ../evidence/scenario2-plan.txt
terraform state show aws_instance.imported > ../evidence/scenario2-import.txt
```

#### Scenario 3: Move Resources Between States

```bash
cd ../scenario-3-move/old-project

# Initialize and create resources
terraform init
terraform apply -auto-approve

# Initialize new project
cd ../new-project
terraform init
cd ../old-project

# Move database to new project
terraform state mv -state-out=../new-project/terraform.tfstate \
  aws_instance.db aws_instance.db

# Verify
terraform state list
cd ../new-project
terraform state list

# COLLECT EVIDENCE
terraform state list > ../../evidence/scenario3-new-state.txt
cd ../old-project
terraform state list > ../../evidence/scenario3-old-state.txt
```

### Step 4: Collect AWS Identity Proof

```bash
cd ../..  # Back to project root

# Prove you used real AWS
aws sts get-caller-identity > evidence/aws-identity.txt

# Optional: Take screenshots of AWS Console showing:
# - S3 bucket with state file
# - EC2 instance you imported
# Save as evidence/screenshot-*.png
```

### Step 5: Verify Your Work

```bash
# Run grading with AWS mode
python run.py --verify --mode aws --evidence
```

### Step 6: Clean Up AWS Resources (IMPORTANT!)

```bash
# Destroy resources to avoid charges
cd scenario-1-local-to-remote
terraform destroy -auto-approve

cd ../scenario-2-import
terraform destroy -auto-approve

cd ../scenario-3-move/old-project
terraform destroy -auto-approve
cd ../new-project
terraform destroy -auto-approve

# Delete S3 bucket
aws s3 rb s3://$STATE_BUCKET --force
```

### Step 7: Submit Your Work

```bash
git add .
git commit -m "Complete terraform-state-migration challenge with Real AWS"
git push origin main
```

</details>

---

## Grading System

### How Verification Works

The `run.py` script checks your work in three ways:

| Check Type | Command | What It Does |
|------------|---------|--------------|
| **File Check** | `python run.py` | Checks if files exist and have correct content |
| **Live Verify** | `python run.py --verify` | Runs terraform commands to verify state |
| **Evidence** | `python run.py --evidence` | Checks for proof files (Real AWS) |

### For LocalStack Users

```bash
# Basic check
python run.py

# Full verification (recommended)
python run.py --verify --mode localstack
```

### For Real AWS Users

```bash
# Create evidence directory first
mkdir -p evidence

# Collect evidence after each scenario:
terraform plan -no-color > evidence/scenario1-plan.txt
terraform state list > evidence/scenario1-state.txt
aws s3 ls s3://your-bucket/ --recursive > evidence/s3-state-proof.txt
aws sts get-caller-identity > evidence/aws-identity.txt

# Run full verification
python run.py --verify --mode aws --evidence
```

### Evidence Files Checklist

For Real AWS submissions, include these files in `evidence/`:

| File | Command to Generate | Purpose |
|------|---------------------|---------|
| `scenario1-plan.txt` | `terraform plan -no-color > evidence/scenario1-plan.txt` | Proves "No changes" |
| `scenario1-state.txt` | `terraform state list > evidence/scenario1-state.txt` | Shows resources in state |
| `s3-state-proof.txt` | `aws s3 ls s3://bucket/ --recursive > evidence/s3-state-proof.txt` | Proves state in S3 |
| `aws-identity.txt` | `aws sts get-caller-identity > evidence/aws-identity.txt` | Proves real AWS account |
| `screenshot-*.png` | Manual screenshot | Visual proof (optional) |

---

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| "Backend configuration changed" | `terraform init -reconfigure` |
| "Resource already in state" | `terraform state rm <resource>` then import again |
| "No changes" not showing after import | Update main.tf to match `terraform state show` output |
| "Error acquiring state lock" | Wait or `terraform force-unlock <LOCK_ID>` |
| LocalStack not responding | `docker-compose down && docker-compose up -d` |

### State Lock Issues

```bash
# Error: state is locked
terraform force-unlock LOCK_ID

# Prevent lock timeout
export TF_LOCK_TIMEOUT=300s
```

### Import Errors

```bash
# Error: Resource already in state
terraform state rm aws_instance.web
terraform import aws_instance.web i-xxx

# Error: Configuration doesn't match
# Run terraform state show and update your config to match
```

---

## Project Structure

```
terraform-state-migration/
├── docker-compose.yml           # LocalStack setup
├── run.py                       # Grading script
├── README.md                    # This file
├── evidence/                    # Your proof files (create this)
│   ├── scenario1-plan.txt
│   ├── scenario1-state.txt
│   ├── s3-state-proof.txt
│   └── aws-identity.txt
├── scenario-1-local-to-remote/  # State migration task
├── scenario-2-import/           # Import existing resources
├── scenario-3-move/             # Move between states
│   ├── old-project/
│   └── new-project/
└── solutions/                   # Reference solutions
```

---

## Scoring

| Component | Points |
|-----------|--------|
| Scenario 1: Files correct | 6 |
| Scenario 2: Files correct | 4 |
| Scenario 3: Files correct | 4 |
| Live Verification (optional) | 6 |
| Evidence Files (Real AWS) | 5 |
| **Total** | **25** |
| **Passing Score** | **60%** |

---

## Best Practices

### 1. Always Backup Before Migration

```bash
# Local state
cp terraform.tfstate terraform.tfstate.backup

# Remote state
terraform state pull > state-backup-$(date +%Y%m%d).json
```

### 2. Enable State Versioning (S3)

```bash
aws s3api put-bucket-versioning \
  --bucket my-state-bucket \
  --versioning-configuration Status=Enabled
```

### 3. Use State Locking (DynamoDB)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"  # Prevents concurrent modifications
  }
}
```

### 4. Document All Migrations

```bash
# Keep a migration log
echo "$(date): Migrated aws_instance.web from local to S3" >> migration.log
```

---

## Next Steps

After completing this challenge:
- [terraform-modules](https://github.com/techlearn-center/terraform-modules) - Build reusable modules
- [aws-iam-advanced](https://github.com/techlearn-center/aws-iam-advanced) - Master IAM policies

---

## Resources

- [Terraform State Documentation](https://developer.hashicorp.com/terraform/language/state)
- [S3 Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [Import Documentation](https://developer.hashicorp.com/terraform/cli/import)
- [State Command Reference](https://developer.hashicorp.com/terraform/cli/commands/state)

---

**Happy State Managing!**
