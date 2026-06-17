#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

FOR_BRANCH="feat/hook-inject-prompt"
UPSTREAM_REMOTE="upstream"

echo "=== Kimi CLI Fork Sync ==="
echo "Branch: $FOR_BRANCH"
echo ""

# Fetch upstream tags
echo "Fetching upstream..."
git fetch "$UPSTREAM_REMOTE" --tags

# Determine latest upstream release tag
UPSTREAM_LATEST=$(git tag --sort=-v:refname | grep -E '^[0-9]+\.[0-9]+' | head -1)
# Determine latest fork tag  
FORK_LATEST=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+.*-fork' | head -1 | sed 's/^v//')
# Current local version
LOCAL_VERSION=$(grep '^version = ' pyproject.toml | sed 's/version = "//;s/"$//')

echo "Upstream latest release: $UPSTREAM_LATEST"
echo "Local pyproject version: $LOCAL_VERSION"
echo "Latest fork tag:         ${FORK_LATEST:-none}"
echo ""

# Check if local branch is up to date with upstream main
LOCAL_MAIN=$(git rev-parse "$UPSTREAM_REMOTE/main")
MERGE_BASE=$(git merge-base HEAD "$UPSTREAM_REMOTE/main")

if [ "$LOCAL_MAIN" = "$MERGE_BASE" ]; then
    echo "✓ Your fork branch already includes upstream/main ($LOCAL_MAIN)"
else
    UPSTREAM_COMMITS=$(git log --oneline "$MERGE_BASE..$UPSTREAM_REMOTE/main" | wc -l | tr -d ' ')
    echo "⚠ Upstream is ahead by $UPSTREAM_COMMITS commits."
    echo ""
    read -rp "Merge upstream/main now? [Y/n] " ans
    if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
        git merge "$UPSTREAM_REMOTE/main" -m "Merge upstream/main into fork"
        
        # Auto-bump version
        BASE_VER=$(echo "$UPSTREAM_LATEST")
        NEW_VER="${BASE_VER}+fork.1"
        
        # If version already ends with +fork.X, increment X
        if [[ "$LOCAL_VERSION" == *+fork.* ]]; then
            BASE_PART="${LOCAL_VERSION%%+fork.*}"
            FORK_NUM="${LOCAL_VERSION##*+fork.}"
            NEW_FORK_NUM=$((FORK_NUM + 1))
            NEW_VER="${BASE_PART}+fork.${NEW_FORK_NUM}"
        fi
        
        sed -i.bak "s/^version = \".*\"/version = \"$NEW_VER\"/" pyproject.toml
        rm -f pyproject.toml.bak
        
        git add pyproject.toml
        git commit -m "Bump fork version to $NEW_VER after upstream merge"
        
        TAG_NAME="v${NEW_VER}"
        git tag -a "$TAG_NAME" -m "Fork release $TAG_NAME"
        
        echo ""
        echo "✓ Merged upstream/main and bumped version to $NEW_VER"
        echo "✓ Tagged: $TAG_NAME"
        echo ""
        echo "==> Reinstalling local kimi-cli..."
        uv tool install --reinstall .
        echo "✓ Reinstalled kimi-cli"
        echo ""
        echo "Next step: git push origin $FOR_BRANCH --tags"
    else
        echo "Skipped merge."
    fi
fi

echo ""
echo "Run 'git push origin $FOR_BRANCH --tags' when ready."
