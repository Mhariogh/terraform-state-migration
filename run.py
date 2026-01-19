#!/usr/bin/env python3
"""
Terraform State Migration Challenge - Progress Checker
=======================================================
Run this script to check your progress on the challenge.

Usage:
    python run.py
"""

import os
import re
import sys

# ANSI colors
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"
BOLD = "\033[1m"

def check_file_exists(filepath):
    """Check if a file exists."""
    return os.path.exists(filepath)

def check_file_contains(filepath, pattern, is_regex=False):
    """Check if a file contains a pattern."""
    if not os.path.exists(filepath):
        return False
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            # Skip commented lines for terraform files
            if filepath.endswith('.tf'):
                lines = content.split('\n')
                uncommented = '\n'.join(
                    line for line in lines
                    if not line.strip().startswith('#')
                )
                content = uncommented
            if is_regex:
                return bool(re.search(pattern, content))
            return pattern in content
    except Exception:
        return False

def print_result(passed, message):
    """Print a check result."""
    if passed:
        print(f"  {GREEN}✓{RESET} {message}")
    else:
        print(f"  {RED}✗{RESET} {message}")
    return passed

def main():
    print(f"\n{BOLD}{BLUE}=" * 60)
    print("       TERRAFORM STATE MIGRATION - PROGRESS CHECKER")
    print("=" * 60 + RESET + "\n")

    checks = []

    # Scenario 1: Local to Remote
    print(f"{BOLD}Scenario 1: Local to Remote Migration{RESET}")
    checks.append(print_result(
        check_file_exists('scenario-1-local-to-remote/backend.tf'),
        "backend.tf exists"
    ))
    checks.append(print_result(
        check_file_contains('scenario-1-local-to-remote/backend.tf', 'backend "s3"'),
        "S3 backend configured"
    ))
    checks.append(print_result(
        check_file_contains('scenario-1-local-to-remote/backend.tf', 'bucket'),
        "Bucket specified in backend"
    ))
    checks.append(print_result(
        check_file_contains('scenario-1-local-to-remote/backend.tf', 'key'),
        "Key specified in backend"
    ))
    checks.append(print_result(
        check_file_contains('scenario-1-local-to-remote/backend.tf', 'region'),
        "Region specified in backend"
    ))
    checks.append(print_result(
        check_file_exists('scenario-1-local-to-remote/create-bucket.sh'),
        "create-bucket.sh exists"
    ))

    # Scenario 2: Import
    print(f"\n{BOLD}Scenario 2: Import Existing Resources{RESET}")
    checks.append(print_result(
        check_file_exists('scenario-2-import/main.tf'),
        "main.tf exists"
    ))
    checks.append(print_result(
        check_file_contains('scenario-2-import/main.tf', 'resource "aws_instance"'),
        "aws_instance resource defined"
    ))
    checks.append(print_result(
        check_file_contains('scenario-2-import/main.tf', 'imported'),
        "Resource named 'imported'"
    ))
    checks.append(print_result(
        check_file_exists('scenario-2-import/setup.sh'),
        "setup.sh exists"
    ))

    # Scenario 3: Move Resources
    print(f"\n{BOLD}Scenario 3: Move Resources Between States{RESET}")
    checks.append(print_result(
        check_file_exists('scenario-3-move/old-project/main.tf'),
        "old-project/main.tf exists"
    ))
    checks.append(print_result(
        check_file_exists('scenario-3-move/new-project/main.tf'),
        "new-project/main.tf exists"
    ))
    checks.append(print_result(
        check_file_contains('scenario-3-move/old-project/main.tf', 'aws_instance'),
        "old-project has aws_instance"
    ))
    checks.append(print_result(
        check_file_contains('scenario-3-move/new-project/main.tf', 'aws_instance') or
        check_file_contains('scenario-3-move/new-project/main.tf', '# resource "aws_instance"'),
        "new-project has aws_instance (or commented template)"
    ))
    checks.append(print_result(
        check_file_exists('scenario-3-move/move-resources.sh'),
        "move-resources.sh exists"
    ))

    # Solutions
    print(f"\n{BOLD}Solutions Reference:{RESET}")
    checks.append(print_result(
        check_file_exists('solutions/scenario-1-backend.tf'),
        "Solution for scenario 1 exists"
    ))
    checks.append(print_result(
        check_file_exists('solutions/scenario-2-main.tf'),
        "Solution for scenario 2 exists"
    ))

    # Docker and support files
    print(f"\n{BOLD}Support Files:{RESET}")
    checks.append(print_result(
        check_file_exists('docker-compose.yml'),
        "docker-compose.yml exists"
    ))
    checks.append(print_result(
        check_file_exists('README.md'),
        "README.md exists"
    ))

    # Calculate results
    passed = sum(checks)
    total = len(checks)
    percentage = (passed / total) * 100 if total > 0 else 0

    # Print summary
    print(f"\n{BOLD}{'=' * 60}")
    print("              CHALLENGE PROGRESS SUMMARY")
    print("=" * 60 + RESET)
    print(f"\n  Total Checks: {total}")
    print(f"  Passed: {GREEN}{passed}{RESET}")
    print(f"  Failed: {RED}{total - passed}{RESET}")
    print(f"\n  Progress: {BOLD}{percentage:.1f}%{RESET}")

    # Progress bar
    bar_width = 40
    filled = int(bar_width * passed / total) if total > 0 else 0
    bar = "█" * filled + "░" * (bar_width - filled)

    if percentage >= 75:
        color = GREEN
    elif percentage >= 50:
        color = YELLOW
    else:
        color = RED

    print(f"\n  [{color}{bar}{RESET}]")

    # Status message
    if percentage == 100:
        print(f"\n  {GREEN}{BOLD}🎉 Congratulations! All checks passed!{RESET}")
        print(f"  {GREEN}You've mastered Terraform State Migration!{RESET}")
    elif percentage >= 75:
        print(f"\n  {GREEN}Great progress! Almost there!{RESET}")
    elif percentage >= 50:
        print(f"\n  {YELLOW}Good progress! Keep going!{RESET}")
    else:
        print(f"\n  {YELLOW}Getting started. Check the README for guidance.{RESET}")

    print()

    # Return exit code
    return 0 if percentage >= 75 else 1

if __name__ == "__main__":
    sys.exit(main())
