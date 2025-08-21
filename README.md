# 🚀 Tide Merge Queue

Production-ready merge queue for GitHub repositories using Tide with Bamboo CI integration.

## ✨ Features

- **Label-based control**: Simple GitHub labels replace merge buttons
- **Priority system**: Normal, high priority, and critical emergency merges
- **Conflict detection**: Automatic rebase with conflict handling
- **Emergency controls**: Pause/resume entire queue with one label
- **Slack notifications**: Optional team alerts for queue status changes
- **Bamboo CI integration**: Works with existing CI/CD pipeline
- **Multi-repository support**: Single queue for multiple repositories

## 🚀 Quick Start

### 1. Prerequisites

- Kubernetes cluster
- Helm 3.x
- kubectl configured
- GitHub Personal Access Token with repo permissions

### 2. Create Secrets

```bash
kubectl create namespace prow

kubectl create secret generic github-token \
  --from-literal=token=<YOUR_GITHUB_PAT> \
  -n prow

kubectl create secret generic github-hmac \
  --from-literal=hmac=<RANDOM_STRING> \
  -n prow
```

### 3. Deploy with Configuration

You can configure GitHub settings in multiple ways:

#### Option A: Single Repository (Traditional)
```bash
# Set your configuration
export GITHUB_ORG="your-org"
export GITHUB_REPO="your-repo" 
export CI_STATUS_CHECK="bamboo/build"

# Deploy with environment variables
helm upgrade --install prow ./prow-helm \
  --namespace prow \
  --set github.org="$GITHUB_ORG" \
  --set github.repo="$GITHUB_REPO" \
  --set tide.requiredStatusChecks[0]="$CI_STATUS_CHECK" \
  --wait
```

#### Option B: Multiple Repositories (Recommended)
```bash
# Set your configuration
export GITHUB_ORG="your-org"
export GITHUB_REPOS="repo1,repo2,repo3"  # Comma-separated list
export CI_STATUS_CHECK="bamboo/build"

# Deploy with multiple repositories
helm upgrade --install prow ./prow-helm \
  --namespace prow \
  --set github.org="$GITHUB_ORG" \
  --set env.GITHUB_REPOS="$GITHUB_REPOS" \
  --set tide.requiredStatusChecks[0]="$CI_STATUS_CHECK" \
  --wait
```

#### Option C: Edit values.yaml
Edit `prow-helm/values.yaml`:
```yaml
github:
  org: "your-org"
  repos:
    - "repo1"
    - "repo2"
    - "repo3"
  
tide:
  requiredStatusChecks: 
    - "bamboo/build"
```

Then deploy:
```bash
helm install prow ./prow-helm -n prow
```

### 4. Create GitHub Labels

Create these labels in **ALL** your repositories:

```bash
merge-queue/add          - #0e8a16 (green)
merge-queue/add-high     - #ff9500 (orange) 
merge-queue/add-critical - #d73a4a (red)
merge-queue/stop         - #d73a4a (red)
merge-queue/conflict     - #fbca04 (yellow)
```

## 📋 Usage

### Normal Merge
1. Create PR in any repository, get approval, wait for CI ✅
2. Add label: `merge-queue/add`
3. Tide automatically rebases + squashes + merges

### High Priority
- Add label: `merge-queue/add-high`
- Merges before normal PRs but respects queue pause

### Emergency (Critical)
- Add label: `merge-queue/add-critical`  
- Bypasses queue pause, merges immediately

### Emergency Stop (Global)
- Add label: `merge-queue/stop` to **any PR in any repository**
- Pauses **entire queue across all repositories** (except critical PRs)
- Manually remove label to resume all queues

## 🏢 Multi-Repository Features

### Global Queue Management
- **Single Tide instance** manages multiple repositories
- **Shared priority system** across all repos
- **Global emergency controls** - stop all repos with one label
- **Consistent labeling** across all repositories

### Per-Repository Flexibility
- Each repository can have different branch protection rules
- Repository-specific CI requirements supported
- Independent conflict resolution per repository
- Repository-specific Slack notifications

### Cross-Repository Priority
- High priority PRs from any repo merge before normal PRs from any repo
- Critical PRs from any repo bypass global queue pause
- Fair processing across repositories

## 🔔 Slack Notifications (Optional)

See `SLACK_SETUP.md` for complete setup instructions.

## 🧪 Testing

See `TESTING_GUIDE.md` for comprehensive testing instructions.

## 📁 Project Structure

```
├── prow-helm/                    # Helm chart
│   ├── templates/
│   │   ├── configmap.yaml       # Tide configuration
│   │   ├── rbac.yaml            # Kubernetes permissions
│   │   ├── services.yaml        # Kubernetes services
│   │   └── tide-only-deployment.yaml # Tide deployment
│   ├── Chart.yaml               # Helm chart metadata
│   └── values.yaml              # Configuration values
├── .github/workflows/
│   └── merge-queue-notifications.yml # Slack notifications
├── deploy-example.sh            # Multi-repo deployment script
├── TIDE_GITHUB_CONTROLS.md     # User guide
├── SLACK_SETUP.md              # Slack setup guide
├── TESTING_GUIDE.md            # Testing instructions
└── README.md                   # This file
```

## 🔧 Configuration

### Key Settings

- **Merge Method**: `rebase` (rebase + squash)
- **Sync Period**: 30 seconds
- **Conflict Handling**: Automatic detection with `merge-queue/conflict` label
- **Branch Protection**: Respects GitHub's required approvals per repository

### Environment Variable Configuration

You can override any configuration value using Helm's `--set` flags:

```bash
# Single repository
--set github.org="my-org"
--set github.repo="my-repo"

# Multiple repositories
--set github.org="my-org"
--set env.GITHUB_REPOS="repo1,repo2,repo3"

# CI configuration  
--set tide.requiredStatusChecks[0]="bamboo/build"
--set tide.requiredStatusChecks[1]="bamboo/test"

# Merge settings
--set tide.mergeMethod="squash"

# Image version
--set tide.image="gcr.io/k8s-prow/tide:v20240101"
```

## 🛠️ Operations

### Check Status
```bash
kubectl get pods -n prow
kubectl logs -n prow deployment/tide -f
```

### Update Configuration
```bash
# Add new repository
helm upgrade prow ./prow-helm \
  --namespace prow \
  --set env.GITHUB_REPOS="repo1,repo2,repo3,new-repo"

# Change organization
helm upgrade prow ./prow-helm \
  --namespace prow \
  --set github.org="new-org"
```

### Troubleshooting
- Check pod logs for errors
- Verify GitHub token has access to **all** repositories
- Confirm CI status check names match across repositories
- Ensure labels exist in **all** repositories

## 🔒 Security

- GitHub token stored as Kubernetes secret
- RBAC permissions limited to necessary resources
- No external endpoints exposed
- Webhook HMAC validation supported
- Single token manages all repositories (ensure proper permissions)

## 📚 Documentation

- **User Guide**: `TIDE_GITHUB_CONTROLS.md`
- **Slack Setup**: `SLACK_SETUP.md`
- **Testing Guide**: `TESTING_GUIDE.md`
- **Tide Documentation**: https://docs.prow.k8s.io/docs/components/tide/

## 🤝 Contributing

1. Test changes in development environment
2. Update documentation if needed
3. Follow semantic versioning for releases

## 📄 License

This project is licensed under the MIT License. 



helm upgrade prow ./prow-helm \
  --namespace prow \
  --set github.org="new-org" \
  --set github.repo="new-repo"
