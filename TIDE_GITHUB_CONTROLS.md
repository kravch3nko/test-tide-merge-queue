# 🏷️ Tide GitHub Controls - User Guide

Simple GitHub label-based merge queue control.

## 📋 Available Labels

| Label | Purpose | Where to Add |
|-------|---------|--------------|
| `merge-queue/add` | Add PR to merge queue | On PRs |
| `merge-queue/stop` | Stop all merging | On Issues |

## 🚀 How to Use

### Normal Merge Process
1. **Create PR** and get required approvals
2. **Wait for CI** - all status checks must pass (enforced by GitHub branch protection)
3. **Add label**: `merge-queue/add`
4. **Tide automatically** rebases + squashes + merges

### Emergency Stop (Global)
1. **Create an issue** in your repository
2. **Add label**: `merge-queue/stop` to the issue
3. **All merging stops** immediately
4. **Close issue** or **remove label** to resume all merging

## 📊 Common Scenarios

### Scenario 1: Regular Feature Merge
```
1. PR created → CI running
2. CI passes ✅ → Add `merge-queue/add`
3. Tide rebases → Tide merges → Done ✅
```

### Scenario 2: Emergency Stop
```
1. Issue detected → Create GitHub issue
2. Add `merge-queue/stop` label to issue
3. All merging stops ⏸️
4. Fix issue → Remove label or close issue
5. Merging resumes ▶️
```

### Scenario 3: Rebase Conflict
```
1. PR in queue → Tide attempts rebase
2. Conflict detected → Tide skips PR and updates status
3. Developer fixes conflicts → Pushes new commit
4. Tide automatically retries → Merges when clean ✅
```

## 🔄 How It Works

### GitHub Branch Protection Integration
- **Tide respects** all your existing GitHub branch protection rules
- **No duplication** of CI check names in Tide configuration
- **Automatic detection** of required status checks, reviews, etc.
- **Consistent behavior** between manual merges and Tide merges

### Automatic Conflict Handling
- **Tide detects conflicts** during rebase attempts
- **Updates PR status** to show conflict information
- **No manual labels** needed - just fix conflicts and push
- **Automatic retry** on next sync cycle

### Global Emergency Control
- **Issue-based stop** - add `merge-queue/stop` to any issue
- **Repository-wide pause** - affects all PRs in the repository
- **Simple resume** - remove label or close issue

## ⚠️ Important Notes

### Label Management
- **One label per PR** - just `merge-queue/add`
- **Issue-based stop** - `merge-queue/stop` goes on issues, not PRs
- **No conflict labels** - Tide handles conflicts automatically
- **GitHub branch protection** handles all CI requirements

### CI Requirements
- **Set up in GitHub** - use branch protection rules
- **Automatic enforcement** - Tide respects these automatically
- **No configuration duplication** - define CI checks once in GitHub

### Repository Behavior
- **Single queue per repository** - all PRs processed in order
- **Automatic rebase** - keeps PRs up to date with main branch
- **Squash merge** - clean commit history

## 🔍 Monitoring

### Check Queue Status
- **PR Status Checks**: Look for Tide status on GitHub PR
- **Labels**: Current labels show PR state
- **Logs**: `kubectl logs -n prow deployment/tide -f`

### Troubleshooting
- **PR not merging**: Check CI status and GitHub branch protection
- **Conflicts**: Look at PR status - Tide will show conflict information
- **Queue paused**: Check for `merge-queue/stop` label on any issue
- **CI not passing**: Fix in GitHub branch protection settings

## 🎯 Quick Reference

| Want to... | Do this |
|------------|---------|
| Merge a PR | Add `merge-queue/add` label to PR |
| Stop all merging | Add `merge-queue/stop` label to any issue |
| Resume merging | Remove `merge-queue/stop` label or close issue |
| Fix conflicts | Push new commits, Tide will retry automatically |
| Add CI checks | Update GitHub branch protection rules |

## 💡 Best Practices

1. **Use GitHub branch protection** for all CI requirements
2. **Create issues for stops** - easier to track and communicate
3. **Document stop reasons** in issue description
4. **Remove stops promptly** when issues are resolved
5. **Let Tide handle conflicts** - no manual intervention needed

This system is designed to be simple, reliable, and integrate seamlessly with your existing GitHub workflow! 