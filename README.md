# �� Tide Merge Queue

Simple merge queue for GitHub repositories using Tide.

## ✨ Features

- **Simple label control**: One label to merge PRs
- **Global emergency stop**: Pause all merging with one label on an issue
- **GitHub branch protection**: Respects your existing CI requirements
- **Multi-repository support**: Single queue for multiple repositories
- **Automatic conflict handling**: No manual label management needed

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

### 3. Configure Repository

Edit `prow-helm/values.yaml`:
```yaml
repositories:
  - org: "your-org"
    name: "your-repo"
```

### 4. Deploy

```bash
helm install prow ./prow-helm -n prow
```

### 5. Create GitHub Labels

Create these labels in your repository:

```bash
merge-queue/add          - #0e8a16 (green)
merge-queue/stop         - #d73a4a (red)
```

## 📋 Usage

### Normal Merge
1. Create PR, get approval, wait for CI ✅
2. Add label: `merge-queue/add`
3. Tide automatically rebases + squashes + merges

### Emergency Stop
1. Create an issue in your repository
2. Add label: `merge-queue/stop` to the issue
3. All merging stops immediately
4. Close issue or remove label to resume

## 🏢 Multi-Repository Setup

Add multiple repositories to `prow-helm/values.yaml`:

```yaml
repositories:
  - org: "my-org"
    name: "backend"
  - org: "my-org"
    name: "frontend"
  - org: "partner-org"
    name: "shared-lib"
```

Each repository operates independently but shares the same Tide instance.

## 🔧 Configuration

### Key Settings

- **Merge Method**: `rebase` (rebase + squash)
- **Sync Period**: 30 seconds
- **Branch Protection**: Respects GitHub's CI requirements automatically

### GitHub Branch Protection

Set up branch protection rules in GitHub to enforce:
- Required status checks (CI/CD)
- Required reviews
- Up-to-date branches

Tide will automatically respect these rules - no need to duplicate CI check names in the configuration.

## 🛠️ Operations

### Check Status
```bash
kubectl get pods -n prow
kubectl logs -n prow deployment/tide -f
```

### Upgrade helm chart
```
helm upgrade --install prow ./prow-helm --namespace prow --wait
kubectl rollout restart deployment -n prow
```

### Add New Repository
1. Edit `prow-helm/values.yaml`
2. Add repository to the list
3. Run: `helm upgrade prow ./prow-helm -n prow`

### Troubleshooting
- Check pod logs for errors
- Verify GitHub token has access to all repositories
- Ensure labels exist in all repositories

## 🔒 Security

- GitHub token stored as Kubernetes secret
- RBAC permissions limited to necessary resources
- No external endpoints exposed (unless using webhooks)

## 📚 Documentation

- **User Guide**: `TIDE_GITHUB_CONTROLS.md`
- **Tide Documentation**: https://docs.prow.k8s.io/docs/components/tide/

## 🎯 Simple and Clean

This setup provides a minimal, maintainable merge queue that:
- Uses only 2 labels
- Respects GitHub branch protection automatically  
- Requires no CI check configuration duplication
- Provides global emergency controls
- Scales to multiple repositories effortlessly
