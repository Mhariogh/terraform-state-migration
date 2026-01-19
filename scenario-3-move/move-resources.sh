#!/bin/bash
# Move Resources Between States
# ==============================
# This script moves database resources from old-project to new-project

echo "Moving database resources from old-project to new-project..."
echo ""

cd old-project

# Check current resources
echo "Current resources in old-project:"
terraform state list
echo ""

# Move database security group
echo "Moving aws_security_group.db..."
terraform state mv \
  -state-out=../new-project/terraform.tfstate \
  aws_security_group.db aws_security_group.db

# Move database instance
echo "Moving aws_instance.db..."
terraform state mv \
  -state-out=../new-project/terraform.tfstate \
  aws_instance.db aws_instance.db

echo ""
echo "=========================================="
echo "  MIGRATION COMPLETE"
echo "=========================================="
echo ""
echo "Remaining in old-project:"
terraform state list
echo ""

cd ../new-project
echo "Now in new-project:"
terraform state list
echo ""

echo "Next steps:"
echo "1. Update old-project/main.tf - remove moved resource blocks"
echo "2. Update new-project/main.tf - add resource blocks"
echo "3. Run 'terraform plan' in both projects to verify no changes"
