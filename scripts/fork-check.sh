#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

git fetch upstream --tags 2>/dev/null

UPSTREAM_LATEST=$(git tag --sort=-v:refname | grep -E '^[0-9]+\.[0-9]+' | head -1)
LOCAL_VERSION=$(grep '^version = ' pyproject.toml | sed 's/version = "//;s/"$//')
FOR_BRANCH=$(git branch --show-current)

echo "Branch:           $FOR_BRANCH"
echo "Upstream latest:  $UPSTREAM_LATEST"
echo "Local version:    $LOCAL_VERSION"

LOCAL_MAIN=$(git rev-parse upstream/main 2>/dev/null)
MERGE_BASE=$(git merge-base HEAD upstream/main 2>/dev/null || true)

if [ -n "$LOCAL_MAIN" ] && [ -n "$MERGE_BASE" ] && [ "$LOCAL_MAIN" = "$MERGE_BASE" ]; then
    echo "Status:           ✓ Up to date with upstream/main"
else
    AHEAD=$(git log --oneline "${MERGE_BASE:-HEAD}..upstream/main" 2>/dev/null | wc -l | tr -d ' ')
    echo "Status:           ⚠ Upstream ahead by $AHEAD commits"
fi
