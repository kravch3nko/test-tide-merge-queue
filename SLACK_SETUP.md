# 🔔 Slack Notifications Setup

Get instant Slack notifications when the merge queue is stopped or resumed!

## 📋 Setup Steps

### 1. Create Slack Webhook
1. Go to your Slack workspace
2. Navigate to **Apps** → **Incoming Webhooks**
3. Click **Add to Slack**
4. Choose the channel where you want notifications (e.g., `#deployments`, `#dev-ops`)
5. Copy the webhook URL (looks like: `https://hooks.slack.com/services/...`)

### 2. Add GitHub Secret
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `SLACK_WEBHOOK_URL`
5. Value: Paste your Slack webhook URL
6. Click **Add secret**

### 3. Test the Integration
1. Create a test PR or issue
2. Add label: `merge-queue/stop`
3. Check your Slack channel for the notification! 🎉
4. Remove the label to test the resume notification

## 📱 What You'll Get

### 🚨 Queue Stopped Notification
```
🚨 MERGE QUEUE STOPPED

Repository: your-org/your-repo
Stopped by: @username
PR/Issue: #123
Time: Jan 15, 2024 at 2:30 PM

All merging is paused except critical PRs. Remove the label to resume.
```

### ✅ Queue Resumed Notification  
```
✅ MERGE QUEUE RESUMED

Repository: your-org/your-repo
Resumed by: @username  
PR/Issue: #123
Time: Jan 15, 2024 at 2:45 PM

Normal merge queue operations have resumed.
```

## 🎯 Benefits

- **Immediate visibility** when queue is paused
- **Know who** stopped/resumed the queue
- **Track duration** of queue pauses
- **Team awareness** of deployment status
- **Audit trail** in Slack

## 🔧 Customization

### Change Slack Channel
Edit the webhook URL to point to a different channel, or create multiple webhooks for different channels.

### Modify Message Format
Edit `.github/workflows/merge-queue-notifications.yml` to customize:
- Message text and formatting
- Additional fields (e.g., reason for stop)
- Colors and emojis
- Mentions (@channel, @here, specific users)

### Add More Notifications
You can extend this to notify on:
- Critical PR merges during pause
- Conflict detection
- Queue length/status
- Failed merges

## 🚨 Troubleshooting

### Notifications Not Working?
1. Check that `SLACK_WEBHOOK_URL` secret is set correctly
2. Verify the webhook URL is valid in Slack
3. Check GitHub Actions logs in the **Actions** tab
4. Ensure the workflow file is in `.github/workflows/` directory

### Wrong Channel?
Update the Slack webhook to point to the correct channel, or create a new webhook.

## 🎉 That's It!

Your team will now get instant Slack notifications for merge queue status changes! 🚀 