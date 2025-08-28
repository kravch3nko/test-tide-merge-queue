#!/bin/bash

# Function to create a branch and PR for a specific file
create_pr_for_file() {
    local file=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local branch_name="test-${file%.*}-${timestamp}"
    
    # Create and checkout new branch
    git checkout -b "$branch_name" main
    
    # Modify the file with timestamp
    echo "Modified at: ${timestamp}" > "$file"
    
    # Stage, commit and push
    git add "$file"
    git commit -m "test: update ${file} at ${timestamp}"
    git push origin "$branch_name"
    
    # Create PR using GitHub CLI
    pr_url=$(gh pr create \
        --title "Test: Update ${file}" \
        --body "Automated PR to test merge queue with ${file}" \
        --base main \
        --head "$branch_name")
    
    # Add merge-queue/add label
    pr_number=$(echo $pr_url | grep -o '[0-9]*$')
    gh pr edit "$pr_number" --add-label "merge-queue/add"
    
    # Return to main branch
    git checkout main
    
    echo "Created PR for ${file}: ${pr_url}"
}

# Ensure we're on main branch and it's up to date
git checkout main
git pull origin main

# Create PRs for each file
create_pr_for_file "changeme.md"
sleep 5  # Wait a bit between PR creations
create_pr_for_file "changeme1.md"

echo "Done! Created 2 PRs for testing."
