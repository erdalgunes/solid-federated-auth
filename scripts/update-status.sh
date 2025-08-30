#!/bin/bash

# Simple status updater for STATUS.md
# Run: ./scripts/update-status.sh

echo "# Project Status" > STATUS.md
echo "" >> STATUS.md
echo "**Last Updated**: $(date '+%B %d, %Y')" >> STATUS.md
echo "" >> STATUS.md

# Get current milestone
echo "## 📍 Current Phase" >> STATUS.md
gh api repos/erdalgunes/solid-federated-auth/milestones --jq '
  .[] | select(.state=="open") | "**\(.title)** - Due: \(.due_on[:10])"
' | head -1 >> STATUS.md
echo "" >> STATUS.md

# Count open/closed issues
echo "## 📋 Issue Summary" >> STATUS.md
OPEN=$(gh issue list --repo erdalgunes/solid-federated-auth --state open --json id --jq 'length')
CLOSED=$(gh issue list --repo erdalgunes/solid-federated-auth --state closed --json id --jq 'length')
echo "- Open: $OPEN" >> STATUS.md
echo "- Closed: $CLOSED" >> STATUS.md
echo "" >> STATUS.md

# List open issues
echo "## 🔄 Active Issues" >> STATUS.md
echo "" >> STATUS.md
gh issue list --repo erdalgunes/solid-federated-auth --state open --limit 10 | while IFS=$'\t' read -r number state title labels updated; do
  echo "- [ ] #$number: $title" >> STATUS.md
done
echo "" >> STATUS.md

# Quick links
echo "## 🔗 Quick Links" >> STATUS.md
echo "- [Project Board](https://github.com/users/erdalgunes/projects/3)" >> STATUS.md
echo "- [Open Issues](https://github.com/erdalgunes/solid-federated-auth/issues)" >> STATUS.md
echo "- [Milestones](https://github.com/erdalgunes/solid-federated-auth/milestones)" >> STATUS.md

echo "✅ STATUS.md updated"