# 🏢 Multi-Repository Setup Guide

This guide shows how to configure Tide for multiple repositories with different CI requirements.

## 🎯 Key Benefits

- ✅ **Per-repository CI checks**: Each repo can have different status checks
- ✅ **Cross-organization support**: Work with multiple GitHub orgs
- ✅ **Repository-specific controls**: Stop individual repos without affecting others
- ✅ **Unified priority system**: High priority PRs from any repo merge first
- ✅ **Simple configuration**: Edit one YAML file to manage all repos

## 📝 Configuration

Edit `prow-helm/values.yaml`:

```yaml
repositories:
  # Python backend with comprehensive checks
  - org: "my-company"
    name: "api-service"
    ciStatusChecks:
      - "ci/pytest"        # Unit tests
      - "ci/ruff"          # Code linting
      - "ci/mypy"          # Type checking
      - "ci/coverage"      # Code coverage
      - "ci/security"      # Security scan

  # Frontend with different tooling
  - org: "my-company"
    name: "web-app"
    ciStatusChecks:
      - "ci/jest"          # JavaScript tests
      - "ci/eslint"        # JS/TS linting
      - "ci/build"         # Build verification
      - "ci/e2e"           # End-to-end tests

  # Infrastructure with Terraform
  - org: "my-company"
    name: "infrastructure"
    ciStatusChecks:
      - "ci/terraform-validate"
      - "ci/terraform-plan"
      - "ci/checkov"       # Security scanning

  # Cross-org collaboration
  - org: "partner-org"
    name: "shared-library"
    ciStatusChecks:
      - "bamboo/build"     # Different CI system
      - "bamboo/test"
```

## 🚀 Deployment

### Option 1: Using values.yaml (Recommended)

1. Edit `prow-helm/values.yaml` with your repositories
2. Deploy:
```bash
helm upgrade --install prow ./prow-helm -n prow --wait
```

### Option 2: Environment Variables (Single Repo)

For single repository with multiple checks:
```bash
export GITHUB_ORG="my-company"
export GITHUB_REPO="api-service"
export CI_STATUS_CHECKS="ci/pytest,ci/ruff,ci/mypy,ci/coverage"

helm upgrade --install prow ./prow-helm \
  --namespace prow \
  --set env.GITHUB_ORG="$GITHUB_ORG" \
  --set env.GITHUB_REPO="$GITHUB_REPO" \
  --set env.CI_STATUS_CHECKS="$CI_STATUS_CHECKS" \
  --wait
```

## 🏷️ GitHub Labels

Create these labels in **ALL** repositories:

| Label | Color | Purpose |
|-------|-------|---------|
| `merge-queue/add` | `#0e8a16` (green) | Normal priority merge |
| `merge-queue/add-high` | `#ff9500` (orange) | High priority (respects repo stop) |
| `merge-queue/add-critical` | `#d73a4a` (red) | Critical (bypasses repo stop) |
| `merge-queue/stop` | `#d73a4a` (red) | Pause this repository only |
| `merge-queue/conflict` | `#fbca04` (yellow) | Auto-added on conflicts |

## 🔄 How It Works

### Per-Repository Processing

Each repository gets its own Tide queries with repository-specific CI checks:

```yaml
# Backend API waits for Python-specific checks
- repos: ["my-company/api-service"]
  labels: ["merge-queue/add"]
  requiredStatusChecks:
    - "ci/pytest"
    - "ci/ruff" 
    - "ci/mypy"
    - "ci/coverage"

# Frontend waits for JavaScript-specific checks  
- repos: ["my-company/web-app"]
  labels: ["merge-queue/add"]
  requiredStatusChecks:
    - "ci/jest"
    - "ci/eslint"
    - "ci/build"
```

### Repository-Specific Emergency Controls

- Add `merge-queue/stop` to **any PR in a specific repository**
- **Only that repository** pauses merging (except critical PRs in that repo)
- Other repositories continue merging normally
- Remove the label to resume that specific repository

### Cross-Repository Priority

- `merge-queue/add-high` PRs from **any repo** merge before normal PRs from **any repo**
- `merge-queue/add-critical` PRs bypass repository-specific stop and merge immediately
- Fair round-robin processing across repositories

## 📊 Example Scenarios

### Scenario 1: Backend Emergency Fix
```bash
# 1. Create hotfix PR in api-service
# 2. Add label: merge-queue/add-critical
# 3. Waits for: ci/pytest, ci/ruff, ci/mypy, ci/coverage
# 4. Merges immediately (bypasses any repo-specific stop)
```

### Scenario 2: Frontend Feature
```bash
# 1. Create feature PR in web-app  
# 2. Add label: merge-queue/add
# 3. Waits for: ci/jest, ci/eslint, ci/build, ci/e2e
# 4. Merges when CI passes and queue is clear
```

### Scenario 3: Repository-Specific Freeze
```bash
# 1. Add merge-queue/stop to ANY PR in api-service repository
# 2. ONLY api-service stops merging
# 3. web-app, infrastructure, etc. continue merging normally
# 4. Critical PRs in api-service still merge (with merge-queue/add-critical)
# 5. Remove stop label to resume api-service repository
```

### Scenario 4: Multiple Repository Stops
```bash
# 1. Add merge-queue/stop to PR in api-service → api-service paused
# 2. Add merge-queue/stop to PR in web-app → web-app paused  
# 3. infrastructure continues merging (no stop label there)
# 4. Remove labels individually to resume each repository
```

## 🔍 Monitoring

### Check Configuration
```bash
# View generated Tide config
kubectl get configmap prow-config -n prow -o yaml

# Check which repos are configured
kubectl get configmap prow-config -n prow -o yaml | grep "repos:"
```

### Monitor Queue Activity
```bash
# Watch Tide logs
kubectl logs -n prow deployment/tide -f

# Check pod status
kubectl get pods -n prow
```

### Verify CI Status Checks
```bash
# List all configured CI checks
kubectl get configmap prow-config -n prow -o yaml | grep -A 20 "context_options"
```

## 🛠️ Adding New Repositories

### Add to Existing Org
```yaml
repositories:
  # ... existing repos ...
  - org: "my-company"
    name: "new-service"
    ciStatusChecks:
      - "ci/pytest"
      - "ci/ruff"
```

### Add New Organization
```yaml
repositories:
  # ... existing repos ...
  - org: "new-org"
    name: "external-service"
    ciStatusChecks:
      - "jenkins/build"
      - "jenkins/test"
```

Deploy changes:
```bash
helm upgrade prow ./prow-helm -n prow --wait
```

## 🚨 Troubleshooting

### Repository Not Processing
1. Check if repository is in configmap: `kubectl get configmap prow-config -n prow -o yaml`
2. Verify GitHub token has access to the repository
3. Confirm CI status check names match exactly

### CI Checks Not Recognized
1. Check status check names in GitHub PR (must match exactly)
2. Verify your CI system reports to the correct context name
3. Update `ciStatusChecks` in values.yaml if needed

### Cross-Org Issues
1. Ensure GitHub token has access to all organizations
2. Check organization permissions in GitHub
3. Verify repository names are correct

## 💡 Best Practices

1. **Consistent Labeling**: Use the same label names across all repositories
2. **Descriptive CI Names**: Use clear context names like `ci/pytest` not just `ci`
3. **Gradual Rollout**: Start with one repository, then expand
4. **Monitor First**: Watch logs when adding new repositories
5. **Repository-Specific Stops**: Use `merge-queue/stop` for individual repo control
6. **Document CI**: Keep track of what each status check does 