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
```yaml
tide:
  config:
    merge_method:
      your-org/your-repo: squash
    queries:
      - repos:
          - your-org/your-repo
        labels:
          - merge-queue/add
        missingLabels:
          - merge-queue/stop
        includeDrafts: false
      # Check for stop label on issues
      - repos:
          - your-org/your-repo
        labels:
          - merge-queue/stop
        state: open
        type: issue
        blocking: true
    github:
      orgs:
        - name: your-org
          repos:
            - name: your-repo
```

3. **Deploy**
```bash
helm install prow ./prow-helm -n prow
```

4. **Create GitHub Labels**
| Label | Purpose | Color |
|-------|---------|-------|
| `merge-queue/add` | Add PR to merge queue | #0e8a16 (green) |
| `merge-queue/stop` | Emergency stop | #d73a4a (red) |

## Usage Guide

### Merging PRs
1. Create PR → Get approvals → Pass CI
2. Add `merge-queue/add` label
3. Tide automatically:
   - Checks branch protection rules
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
- **Sync Period**: 30 seconds
- **Batch Size**: 1 (no batching)
- **Branch Protection**: Automatic integration

### Multi-Repository Setup
Add repositories to `values.yaml`:
```yaml
tide:
  config:
    merge_method:
      org1/repo1: squash
      org1/repo2: squash
    queries:
      - repos:
          - org1/repo1
          - org1/repo2
        labels:
          - merge-queue/add
    github:
      orgs:
        - name: org1
          repos:
            - name: repo1
            - name: repo2
```

## Operations

### Monitoring
- View pod status: `kubectl get pods -n prow`
- Check logs: `kubectl logs -n prow deployment/tide -f`
- PR status shows in GitHub UI
- Labels indicate current state

### Updates
```bash
helm upgrade prow ./prow-helm -n prow --wait
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

## Reference
- [Tide Documentation](https://docs.prow.k8s.io/docs/components/tide/)




