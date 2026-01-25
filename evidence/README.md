# Evidence Directory

This folder is for **Real AWS users** to store proof of completion.

## Required Files

After completing each scenario, run these commands to collect evidence:

### Scenario 1: State Migration
```bash
cd scenario-1-local-to-remote
terraform plan -no-color > ../evidence/scenario1-plan.txt
terraform state list > ../evidence/scenario1-state.txt
aws s3 ls s3://YOUR-BUCKET/ --recursive > ../evidence/s3-state-proof.txt
```

### Scenario 2: Import
```bash
cd scenario-2-import
terraform plan -no-color > ../evidence/scenario2-plan.txt
terraform state show aws_instance.imported > ../evidence/scenario2-import.txt
```

### Scenario 3: Move Resources
```bash
cd scenario-3-move/old-project
terraform state list > ../../evidence/scenario3-old-state.txt
cd ../new-project
terraform state list > ../../evidence/scenario3-new-state.txt
```

### Scenario 4: Backend Migration
```bash
cd scenario-4-backend-migration
terraform plan -no-color > ../evidence/scenario4-plan.txt
terraform state list > ../evidence/scenario4-state.txt
aws s3 ls s3://YOUR-TARGET-BUCKET/ --recursive > ../evidence/scenario4-bucket-b.txt
```

### Scenario 5: State Recovery
```bash
cd scenario-5-state-recovery
terraform plan -no-color > ../evidence/scenario5-plan.txt
terraform state list > ../evidence/scenario5-state.txt
```

### AWS Identity (Required)
```bash
aws sts get-caller-identity > evidence/aws-identity.txt
```

## Checklist

### Scenario 1: Local to Remote
- [ ] `scenario1-plan.txt` - Shows "No changes" after migration
- [ ] `scenario1-state.txt` - Shows resources in state
- [ ] `s3-state-proof.txt` - Shows state file in S3 bucket

### Scenario 2: Import
- [ ] `scenario2-plan.txt` - Shows "No changes" after import
- [ ] `scenario2-import.txt` - Shows imported resource details

### Scenario 3: Move Resources
- [ ] `scenario3-old-state.txt` - Shows remaining resources in old project
- [ ] `scenario3-new-state.txt` - Shows moved resources in new project

### Scenario 4: Backend Migration
- [ ] `scenario4-plan.txt` - Shows "No changes" after migration
- [ ] `scenario4-state.txt` - Shows resources in state
- [ ] `scenario4-bucket-b.txt` - Shows state file in target bucket

### Scenario 5: State Recovery
- [ ] `scenario5-plan.txt` - Shows "No changes" after recovery
- [ ] `scenario5-state.txt` - Shows all 3 recovered resources

### Required
- [ ] `aws-identity.txt` - Proves you used real AWS account

## Optional Screenshots

You can also add screenshots (PNG/JPG) of:
- AWS S3 Console showing your state bucket
- AWS EC2 Console showing imported instance
- Terminal showing terraform commands

Name them like:
- `screenshot-s3-bucket.png`
- `screenshot-ec2-instance.png`

## Verify Evidence

Run this to check your evidence files:
```bash
python run.py --evidence
```
