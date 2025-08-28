# Tide Merge Queue

Simple GitHub merge queue using Tide, focused on simplicity and reliability.

## Features

- **One-Label Control**: Single label to manage PR merges
- **Emergency Stop**: Global pause with one issue label
- **Branch Protection**: Automatic integration with GitHub CI rules
- **Multi-Repository**: Shared queue across repositories
- **Conflict Handling**: Automatic rebase and retry

## Quick Start

### Prerequisites
- Kubernetes cluster with Helm 3.x and kubectl
- GitHub PAT with repo permissions

### Installation

1. **Create Namespace and Secrets**
```bash
kubectl create namespace prow

kubectl create secret generic github-token \
  --from-literal=token=<YOUR_GITHUB_PAT> \
  -n prow
```

2. **Configure Values**
Edit `prow-helm/values.yaml`:

3. **Deploy**
```bash
helm install prow ./prow-helm -n prow -f prow-helm/Values.yaml
```

4. **Create GitHub Labels**
| Label | Purpose | Color |
|-------|---------|-------|
| `merge-queue/add` | Add PR to merge queue | #0e8a16 (green) |
| `merge-queue/stop` | Emergency stop | #d73a4a (red) |

## Usage Guide

### Merging PRs
1. Create PR → Get approvals → Pass CI
   - Review approvals are required by default
   - At least one approval is needed to proceed
2. Add `merge-queue/add` label
3. Tide automatically:
   - Checks branch protection rules
   - Verifies review approvals
   - Rebases PR if needed
   - Squash merges when ready

### Emergency Stop
1. Create issue → Add `merge-queue/stop` label
2. All merging stops immediately
3. Remove label or close issue to resume

### Handling Conflicts
- Tide detects conflicts during rebase
- Updates PR status with details
- Just fix conflicts and push - no labels needed
- Automatic retry on next sync cycle

### Branch Protection
- Tide respects GitHub branch protection rules
- Required status checks enforced automatically
- No need to duplicate CI configuration
- Set up rules in GitHub repository settings

## Configuration

### Key Settings
- **Merge Method**: Squash (configurable per repo)
- **Sync Period**: 10 seconds
- **Batch Size**: Configurable per organization (set to -1 for unlimited batching)
- **Branch Protection**: Automatic integration

### Multi-Repository Setup
Add repositories to `values.yaml`:
```yaml
tide:
  image: "gcr.io/k8s-prow/tide:latest"
  sync_period: "10s"
  status_update_period: "10s"
  context_options:
    from-branch-protection: true
  batch_size_limit:
    "org1/*": -1  # -1 means unlimited batch size
  merge_method:
    org1/repo1: squash
  blocker_label: "merge-queue/stop"
  queries:
  - repos:
    - org1/repo1
    labels:
    - "merge-queue/add"
    reviewApprovedRequired: true
  max_goroutines: 20

github:
  secret_name: "github-token"
  orgs:
  - name: org1
    repos:
    - name: repo1
```

## Operations

### Monitoring
- View pod status: `kubectl get pods -n prow`
- Check logs: `kubectl logs -n prow deployment/tide -f`
- PR status shows in GitHub UI
- Labels indicate current state

### Updates
```bash
helm upgrade prow ./prow-helm -n prow -f prow-helm/Values.yaml --wait
kubectl rollout restart deployment -n prow
```

### Troubleshooting
- PR stuck: Check CI status and branch protection
- Conflicts: Check PR status for details
- Queue paused: Look for `merge-queue/stop` issues
- CI issues: Verify branch protection settings

### Security
- Secrets stored in Kubernetes
- Limited RBAC permissions
- No external endpoints (default)

## Best Practices
1. Use GitHub branch protection for CI rules
2. Create descriptive stop issues
3. Remove stops promptly when resolved
4. Let Tide handle conflicts automatically
5. Keep PR branches up to date

## Automated PR Management

### Auto-Rebase Workflow
This repository includes an automated GitHub Action that helps keep pull requests up to date with the main branch:

- Automatically rebases PRs when they fall behind the main branch
- Runs every 6 hours and on main branch updates
- Can be manually triggered if needed
- Adds comments to PRs about rebase status
- Handles conflicts gracefully with notifications

If a rebase fails due to conflicts, the action will:
1. Leave a comment on the PR notifying about the conflicts
2. Skip the PR until conflicts are resolved manually
3. Try again on the next run after conflicts are resolved

## Reference
- [Tide Documentation](https://docs.prow.k8s.io/docs/components/tide/)




