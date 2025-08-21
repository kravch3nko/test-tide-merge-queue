#!/bin/bash

# Example deployment script for Tide Multi-Repository Setup
# This demonstrates different approaches for configuring multiple repositories

set -e

echo "🚀 Tide Merge Queue - Flexible Multi-Repository Deployment"
echo "=========================================================="
echo ""

# Check if required environment variables are set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Missing required environment variables!"
    echo ""
    echo "Please set:"
    echo "  export GITHUB_TOKEN=\"ghp_xxxxxxxxxxxx\""
    echo ""
    echo "Choose ONE deployment approach:"
    echo ""
    echo "🔹 Approach 1: Single Repository (Legacy)"
    echo "  export GITHUB_ORG=\"my-org\""
    echo "  export GITHUB_REPO=\"my-repo\""
    echo ""
    echo "🔹 Approach 2: Same-Org Multiple Repos (Simple)"
    echo "  Edit prow-helm/values.yaml:"
    echo "  repositories:"
    echo "    - org: \"my-org\""
    echo "      name: \"repo1\""
    echo "    - org: \"my-org\""
    echo "      name: \"repo2\""
    echo ""
    echo "🔹 Approach 3: Cross-Org with Custom CI (Advanced)"
    echo "  Edit prow-helm/values.yaml:"
    echo "  repositories:"
    echo "    - org: \"org1\""
    echo "      name: \"repo1\""
    echo "      ciStatusCheck: \"bamboo/build\""
    echo "    - org: \"org2\""
    echo "      name: \"repo2\""
    echo "      ciStatusCheck: \"jenkins/test\""
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Determine deployment mode
if [ -n "$GITHUB_ORG" ] && [ -n "$GITHUB_REPO" ]; then
    echo "📋 Single Repository Mode:"
    echo "  GitHub Org: $GITHUB_ORG"
    echo "  Repository: $GITHUB_REPO"
    DEPLOYMENT_MODE="single"
else
    echo "📋 Multi-Repository Mode (using values.yaml configuration)"
    DEPLOYMENT_MODE="multi"
fi

# Set defaults
CI_STATUS_CHECK="${CI_STATUS_CHECK:-continuous-integration/bamboo}"
echo "  Default CI Status Check: $CI_STATUS_CHECK"
echo ""

# Create namespace and secrets
echo "🔐 Creating namespace and secrets..."
kubectl create namespace prow --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic github-token \
  --from-literal=token="$GITHUB_TOKEN" \
  -n prow \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic github-hmac \
  --from-literal=hmac="$(openssl rand -hex 20)" \
  -n prow \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets created"
echo ""

# Deploy based on mode
echo "🚀 Deploying Tide with Helm..."

if [ "$DEPLOYMENT_MODE" = "single" ]; then
    echo "Deploying for single repository: $GITHUB_ORG/$GITHUB_REPO"
    helm upgrade --install prow ./prow-helm \
      --namespace prow \
      --set env.GITHUB_ORG="$GITHUB_ORG" \
      --set env.GITHUB_REPO="$GITHUB_REPO" \
      --set env.CI_STATUS_CHECK="$CI_STATUS_CHECK" \
      --wait
else
    echo "Deploying for multiple repositories (check values.yaml for configuration)"
    helm upgrade --install prow ./prow-helm \
      --namespace prow \
      --set tide.defaultCiStatusCheck="$CI_STATUS_CHECK" \
      --wait
fi

echo "✅ Deployment complete!"
echo ""

# Verify deployment
echo "🔍 Verifying deployment..."
kubectl get pods -n prow

echo ""
echo "🎉 Tide is now running!"
echo ""

# Show configuration
echo "📋 Current Configuration:"
kubectl get configmap prow-config -n prow -o yaml | grep -A 20 "repositories:" || echo "  Using values.yaml repository configuration"

echo ""
echo "Next steps:"
echo "1. Create GitHub labels in ALL your repositories:"
echo "   - merge-queue/add (green)"
echo "   - merge-queue/add-high (orange)"
echo "   - merge-queue/add-critical (red)"
echo "   - merge-queue/stop (red)"
echo ""
echo "2. Test with a PR in any repository:"
echo "   - Create a PR and get it approved"
echo "   - Add 'merge-queue/add' label"
echo "   - Watch it merge automatically!"
echo ""
echo "3. Monitor logs:"
echo "   kubectl logs -n prow deployment/tide -f" 
