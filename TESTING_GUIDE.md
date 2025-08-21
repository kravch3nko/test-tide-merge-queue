# 🧪 Testing Guide - Tide Merge Queue

Complete step-by-step guide to test your Tide merge queue functionality.

## 📋 Pre-Test Checklist

### ✅ Verify Deployment
```bash
# Check Tide is running
kubectl get pods -n prow
# Should show: tide-xxx-xxx   1/1     Running

# Check logs for errors
kubectl logs -n prow deployment/tide --tail=10
# Should show: "Synced" and "Statuses synced" messages
```

### ✅ Verify Configuration
```bash
# Check current configuration
kubectl get configmap prow-config -n prow -o yaml
# Verify your GitHub org/repo and CI check names are correct
```

### ✅ GitHub Repository Setup
1. **Update `prow-helm/values.yaml`** with your actual values:
   ```yaml
   github:
     org: "your-actual-org"
     repo: "your-actual-repo"
   tide:
     requiredStatusChecks: 
       - "your-actual-ci-check-name"  # e.g., "bamboo/build"
   ```

2. **Deploy updated configuration**:
   ```bash
   helm upgrade prow ./prow-helm -n prow
   ```

3. **Create GitHub labels** in your repository:
   - `merge-queue/add` - #0e8a16 (green)
   - `merge-queue/add-high` - #ff9500 (orange)
   - `merge-queue/add-critical` - #d73a4a (red)
   - `merge-queue/stop` - #d73a4a (red)
   - `merge-queue/conflict` - #fbca04 (yellow)

## 🧪 Test Scenarios

### Test 1: Normal Merge Flow ✅

**Objective**: Verify basic merge queue functionality

**Steps**:
1. **Create a test PR**:
   ```bash
   git checkout -b test-merge-queue-1
   echo "Test change 1" >> test-file.txt
   git add test-file.txt
   git commit -m "Test: Normal merge queue flow"
   git push origin test-merge-queue-1
   ```

2. **Create PR in GitHub**:
   - Go to your repository
   - Create PR from `test-merge-queue-1` to `main`
   - Title: "Test: Normal merge queue flow"

3. **Get required approval**:
   - Get someone to approve the PR (or approve yourself if allowed)
   - Wait for CI to pass (Bamboo should report success)

4. **Add merge label**:
   - Add label: `merge-queue/add`

5. **Monitor Tide logs**:
   ```bash
   kubectl logs -n prow deployment/tide -f
   ```

**Expected Results**:
- ✅ Tide detects PR with `merge-queue/add` label
- ✅ PR appears in merge pool
- ✅ Tide rebases PR against latest main
- ✅ Tide squashes commits and merges
- ✅ PR is automatically closed
- ✅ Branch is deleted (if configured)

---

### Test 2: Conflict Detection 🔄

**Objective**: Verify automatic conflict detection and handling

**Steps**:
1. **Create conflicting changes**:
   ```bash
   # First, make a change directly to main
   git checkout main
   git pull origin main
   echo "Direct change to main" >> test-file.txt
   git add test-file.txt
   git commit -m "Direct change to main"
   git push origin main
   
   # Then create a conflicting PR
   git checkout -b test-conflict
   echo "Conflicting change" >> test-file.txt
   git add test-file.txt
   git commit -m "Test: Conflict detection"
   git push origin test-conflict
   ```

2. **Create PR and add label**:
   - Create PR from `test-conflict` to `main`
   - Get approval and wait for CI
   - Add label: `merge-queue/add`

**Expected Results**:
- ✅ Tide attempts to rebase
- ✅ Tide detects conflict
- ✅ Tide adds `merge-queue/conflict` label automatically
- ✅ PR is removed from merge pool
- ✅ Logs show conflict detection message

3. **Resolve conflict**:
   ```bash
   git checkout test-conflict
   git rebase origin/main
   # Resolve conflicts manually
   git add test-file.txt
   git rebase --continue
   git push --force-with-lease origin test-conflict
   ```

4. **Remove conflict label**:
   - Remove `merge-queue/conflict` label from PR
   - Keep `merge-queue/add` label

**Expected Results**:
- ✅ PR re-enters merge pool
- ✅ Tide successfully merges PR

---

### Test 3: Priority System ⚡

**Objective**: Verify high priority merges before normal ones

**Steps**:
1. **Create two PRs**:
   ```bash
   # Normal priority PR
   git checkout -b test-normal
   echo "Normal priority change" >> normal.txt
   git add normal.txt
   git commit -m "Test: Normal priority"
   git push origin test-normal
   
   # High priority PR
   git checkout main
   git checkout -b test-high
   echo "High priority change" >> high.txt
   git add high.txt
   git commit -m "Test: High priority"
   git push origin test-high
   ```

2. **Create PRs and get approvals**:
   - Create both PRs
   - Get approvals and wait for CI on both

3. **Add labels in order**:
   - First: Add `merge-queue/add` to normal priority PR
   - Then: Add `merge-queue/add-high` to high priority PR

4. **Monitor merge order**:
   ```bash
   kubectl logs -n prow deployment/tide -f
   ```

**Expected Results**:
- ✅ High priority PR merges first
- ✅ Normal priority PR merges second
- ✅ Logs show correct processing order

---

### Test 4: Emergency Stop & Critical Override 🚨

**Objective**: Verify emergency stop and critical bypass functionality

**Steps**:
1. **Create test PRs**:
   ```bash
   # Normal PR
   git checkout -b test-normal-stop
   echo "Normal during stop" >> normal-stop.txt
   git add normal-stop.txt
   git commit -m "Test: Normal during stop"
   git push origin test-normal-stop
   
   # Critical PR
   git checkout main
   git checkout -b test-critical
   echo "Critical emergency fix" >> critical.txt
   git add critical.txt
   git commit -m "Test: Critical emergency"
   git push origin test-critical
   ```

2. **Pause the queue**:
   - Create a dummy issue or use existing PR
   - Add label: `merge-queue/stop`
   - Verify Slack notification (if configured)

3. **Try normal merge**:
   - Create PR from `test-normal-stop`
   - Get approval, wait for CI
   - Add label: `merge-queue/add`

**Expected Results**:
- ❌ Normal PR does NOT merge (blocked by stop)
- ✅ Logs show PR is blocked by `merge-queue/stop`

4. **Test critical bypass**:
   - Create PR from `test-critical`
   - Get approval, wait for CI
   - Add label: `merge-queue/add-critical`

**Expected Results**:
- ✅ Critical PR merges immediately (bypasses stop)
- ❌ Normal PR still blocked

5. **Resume queue**:
   - Remove `merge-queue/stop` label
   - Verify Slack notification (if configured)

**Expected Results**:
- ✅ Normal PR now merges
- ✅ Queue resumes normal operation

---

### Test 5: Label Management 🏷️

**Objective**: Verify label addition/removal behavior

**Steps**:
1. **Create test PR**:
   ```bash
   git checkout -b test-labels
   echo "Label test" >> labels.txt
   git add labels.txt
   git commit -m "Test: Label management"
   git push origin test-labels
   ```

2. **Test label scenarios**:
   - Create PR, get approval, wait for CI
   - Add `merge-queue/add` → Should enter queue
   - Remove `merge-queue/add` → Should leave queue
   - Add `merge-queue/add-high` → Should enter high priority queue
   - Change to `merge-queue/add-critical` → Should enter critical queue

**Expected Results**:
- ✅ PR enters/leaves queue based on labels
- ✅ Priority changes are respected
- ✅ Only one merge label should be active at a time

---

## 🔍 Monitoring & Debugging

### Real-time Monitoring
```bash
# Watch Tide logs continuously
kubectl logs -n prow deployment/tide -f

# Check PR status in another terminal
kubectl get prowjobs -n prow

# Monitor pod status
watch kubectl get pods -n prow
```

### Common Log Messages

**✅ Success Messages**:
```
"Synced" - Tide completed a sync cycle
"Statuses synced" - PR statuses updated
"In merge pool" - PR is ready to merge
```

**⚠️ Warning Messages**:
```
"failed to merge" - Merge conflict or other issue
"missing required status checks" - CI not complete
"missing required labels" - Labels not correct
```

**❌ Error Messages**:
```
"failed to get restmapping" - RBAC or CRD issues
"GitHub API rate limit" - Too many API calls
```

## 🚨 Troubleshooting

### PR Not Entering Queue
1. **Check labels**: Ensure correct merge label is applied
2. **Check CI status**: Verify required status checks are passing
3. **Check approvals**: Ensure GitHub branch protection requirements are met
4. **Check Tide logs**: Look for specific error messages

### PR Stuck in Queue
1. **Check for conflicts**: Look for `merge-queue/conflict` label
2. **Check CI status**: Ensure status checks are still passing
3. **Check queue pause**: Look for `merge-queue/stop` label
4. **Restart Tide**: `kubectl rollout restart deployment/tide -n prow`

### Tide Not Running
1. **Check pod status**: `kubectl get pods -n prow`
2. **Check logs**: `kubectl logs -n prow deployment/tide`
3. **Check secrets**: Verify GitHub token is valid
4. **Check RBAC**: Ensure proper permissions

## ✅ Test Completion Checklist

After running all tests, verify:

- [ ] Normal merge flow works
- [ ] Conflict detection and resolution works
- [ ] Priority system works (high before normal)
- [ ] Emergency stop blocks normal/high PRs
- [ ] Critical PRs bypass emergency stop
- [ ] Queue resumes after removing stop label
- [ ] Labels can be added/removed dynamically
- [ ] Slack notifications work (if configured)
- [ ] Tide logs show expected behavior
- [ ] No error messages in logs

## 🎉 Success!

If all tests pass, your Tide merge queue is ready for production use! 🚀

## 📞 Need Help?

- Check Tide logs: `kubectl logs -n prow deployment/tide -f`
- Review configuration: `kubectl get configmap prow-config -n prow -o yaml`
- Verify GitHub token permissions
- Ensure CI status check names match exactly
- Check GitHub repository labels exist 