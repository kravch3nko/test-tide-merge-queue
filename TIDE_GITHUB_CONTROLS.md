# 🏷️ Tide GitHub Controls - User Guide

This guide explains how to control the Tide merge queue using GitHub labels.

## 📋 Available Labels

### Action Labels (Choose One)

| Label | Purpose | Priority | Respects Stop |
|-------|---------|----------|---------------|
| `merge-queue/add` | Add PR to merge queue | Normal | ✅ Yes |
| `merge-queue/add-high` | High priority merge | High | ✅ Yes |
| `merge-queue/add-critical` | Emergency merge | Critical | ❌ No (bypasses) |

### Control Labels

| Label | Purpose | Scope |
|-------|---------|-------|
| `merge-queue/stop` | Pause merge queue | This repository only |
| `merge-queue/conflict` | Rebase conflict detected | Auto-added by Tide |

## 🚀 How to Use

### Normal Merge Process
1. **Create PR** and get required approvals
2. **Wait for CI** - all status checks must pass
3. **Add label**: `merge-queue/add`
4. **Tide automatically** rebases + squashes + merges

### High Priority Merge
- Add label: `merge-queue/add-high`
- Merges before normal priority PRs
- Still respects repository stop controls
- Waits for all CI checks to pass

### Emergency/Critical Merge
- Add label: `merge-queue/add-critical`
- **Bypasses repository stop** - merges even if repo is paused
- Highest priority - merges immediately when CI passes
- Use sparingly for hotfixes and critical issues

### Repository-Specific Emergency Stop
- Add label: `merge-queue/stop` to **any PR in the repository**
- **Pauses merge queue for this repository only**
- Other repositories continue merging normally
- Critical PRs (`merge-queue/add-critical`) still merge
- **Manually remove** the label to resume this repository

## 📊 Common Scenarios

### Scenario 1: Regular Feature Merge
```
1. PR created → CI running
2. CI passes ✅ → Add `merge-queue/add`
3. Tide rebases → Tide merges → Done ✅
```

### Scenario 2: Urgent Bug Fix
```
1. Hotfix PR created → CI running  
2. CI passes ✅ → Add `merge-queue/add-high`
3. Jumps ahead of normal PRs → Merges next ✅
```

### Scenario 3: Critical Production Issue
```
1. Emergency PR created → CI running
2. CI passes ✅ → Add `merge-queue/add-critical`
3. Bypasses any stops → Merges immediately ✅
```

### Scenario 4: Repository-Specific Freeze
```
1. Issue detected in this repository
2. Add `merge-queue/stop` to any PR in this repo
3. This repository pauses ⏸️ (other repos continue)
4. Critical PRs still merge with `merge-queue/add-critical`
5. Remove `merge-queue/stop` to resume this repository
```

### Scenario 5: Rebase Conflict
```
1. PR in queue → Tide attempts rebase
2. Conflict detected → Tide adds `merge-queue/conflict`
3. PR removed from queue → Manual resolution needed
4. Fix conflicts → Remove `merge-queue/conflict` → Re-add action label
```

## 🔄 Queue Behavior

### Priority Order
1. **Critical** (`merge-queue/add-critical`) - bypasses repository stops
2. **High** (`merge-queue/add-high`) - respects repository stops  
3. **Normal** (`merge-queue/add`) - respects repository stops

### Repository-Specific Controls
- Each repository has independent queue control
- `merge-queue/stop` only affects the repository where it's added
- Multiple repositories can be stopped independently
- Critical PRs bypass repository-specific stops

### Automatic Actions
- **Conflict Detection**: Tide adds `merge-queue/conflict` on rebase failures
- **Queue Removal**: PRs with conflicts are automatically removed from queue
- **Status Updates**: Tide updates GitHub status checks during processing

## ⚠️ Important Notes

### Label Management
- **One action label per PR** - don't mix `add`, `add-high`, `add-critical`
- **Repository-specific stop** - affects only the repository where added
- **Manual conflict resolution** - remove `merge-queue/conflict` after fixing
- **Critical bypass** - use `merge-queue/add-critical` responsibly

### CI Requirements
- **All status checks must pass** before any merge
- **Different repos have different CI checks** (pytest, ruff, jest, etc.)
- **Tide waits for all required checks** regardless of priority level

### Repository Isolation
- **Independent queues** - each repository processes separately
- **Shared priority system** - high priority from any repo goes first
- **Repository-specific stops** - pause individual repos without affecting others

## 🔍 Monitoring

### Check Queue Status
- **PR Status Checks**: Look for Tide status on GitHub PR
- **Labels**: Current labels show PR state and priority
- **Logs**: `kubectl logs -n prow deployment/tide -f`

### Troubleshooting
- **PR not merging**: Check CI status and required labels
- **Conflicts**: Look for `merge-queue/conflict` label
- **Repository paused**: Check for `merge-queue/stop` label in any PR
- **Wrong priority**: Verify only one action label is present

## 🎯 Quick Reference

| Want to... | Add this label |
|------------|----------------|
| Merge normally | `merge-queue/add` |
| Merge with high priority | `merge-queue/add-high` |
| Emergency merge (bypass stop) | `merge-queue/add-critical` |
| Pause this repository | `merge-queue/stop` |
| Resume after conflict | Remove `merge-queue/conflict`, re-add action label |

Remember: Repository stops are **repository-specific** - stopping one repo doesn't affect others! 