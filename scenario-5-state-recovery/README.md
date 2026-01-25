# Scenario 5: State Recovery

## The Scenario

Your production Terraform state file was accidentally deleted. The resources still exist in AWS, but Terraform doesn't know about them.

**Your mission:** Rebuild the state file by importing all existing resources.

## Why This Matters

State loss happens in real life:
- Someone deleted `terraform.tfstate` thinking it was temporary
- S3 bucket with state was accidentally removed
- State file corruption after a failed migration
- New team member runs `terraform apply` without state

Without recovery skills, teams often:
- ❌ Re-create resources (causes downtime)
- ❌ Manually edit state (dangerous)
- ❌ Abandon Terraform for those resources

## Your Task

### Step 1: Simulate the Disaster

```bash
cd scenario-5-state-recovery

# Run the disaster simulation
chmod +x simulate-disaster.sh
./simulate-disaster.sh   # Linux/Mac
# OR
.\simulate-disaster.ps1  # Windows PowerShell
```

This creates:
- 1 EC2 instance
- 1 Security Group
- 1 EBS Volume

And "loses" the state file.

### Step 2: Observe the Problem

```bash
terraform init
terraform plan
```

Terraform will show it wants to CREATE 3 resources - but they already exist!

### Step 3: Recover the State

Check `resource-ids.txt` for the IDs, then import each resource:

```bash
# Read the resource IDs
cat resource-ids.txt

# Import each resource
terraform import aws_instance.web <INSTANCE_ID>
terraform import aws_security_group.web <SECURITY_GROUP_ID>
terraform import aws_ebs_volume.data <VOLUME_ID>
```

### Step 4: Verify Recovery

```bash
terraform plan
# Should show: "No changes. Your infrastructure matches the configuration."
```

## Success Criteria

- [ ] All 3 resources imported into state
- [ ] `terraform state list` shows all resources
- [ ] `terraform plan` shows "No changes"

## Tips

1. **Check imported attributes:** `terraform state show aws_instance.web`
2. **If plan shows changes:** Update main.tf to match actual resource attributes
3. **List what's in state:** `terraform state list`

## Common Errors

| Error | Solution |
|-------|----------|
| "Resource already exists in state" | `terraform state rm <resource>` then re-import |
| "Plan shows changes after import" | Update main.tf to match `terraform state show` output |
| "Cannot find resource" | Verify the resource ID is correct |
