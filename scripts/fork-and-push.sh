#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

REPO="kevinpostal/kimi-cli"
BRANCH="feat/hook-inject-prompt"
TAG="v1.31.0-fork.1"

echo "=== Fork & Push Helper ==="
echo ""

# Check if fork exists
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/${REPO}")

if [ "$STATUS" = "404" ]; then
    echo "Fork not found on GitHub."
    echo ""
    echo "Please create it manually:"
    echo "  https://github.com/MoonshotAI/kimi-cli/fork"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✓ Fork exists: https://github.com/$REPO"
echo "Pushing branch $BRANCH and tag $TAG..."
git push origin "$BRANCH"
git push origin "$TAG"
echo ""
echo "✓ Done!"
echo "  Branch: https://github.com/$REPO/tree/$BRANCH"
echo "  Tag:    https://github.com/$REPO/releases/tag/$TAG"
