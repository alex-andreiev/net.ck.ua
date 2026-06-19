#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/.site_build}"
BRANCH="$(git -C "$ROOT_DIR" branch --show-current)"
COMMIT_MESSAGE="${1:-}"

if [[ -z "$COMMIT_MESSAGE" ]]; then
  echo "Usage: $0 \"commit message\"" >&2
  exit 1
fi

if [[ ! -f "$ROOT_DIR/Gemfile" ]]; then
  echo "Gemfile not found in $ROOT_DIR" >&2
  exit 1
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler is not installed. Install it first: gem install bundler" >&2
  exit 1
fi

if ! bundle exec jekyll build --source "$ROOT_DIR/docs" --destination "$BUILD_DIR"; then
  echo "Jekyll build failed. Commit aborted." >&2
  exit 1
fi

if [[ ! -f "$BUILD_DIR/index.html" ]]; then
  echo "Build output is incomplete: $BUILD_DIR/index.html not found" >&2
  exit 1
fi

git -C "$ROOT_DIR" add docs Gemfile .gitignore scripts/deploy_pages.sh .github/workflows/jekyll.yml

if git -C "$ROOT_DIR" diff --cached --quiet; then
  echo "No staged changes to commit. Local build passed." >&2
  exit 0
fi

git -C "$ROOT_DIR" commit -m "$COMMIT_MESSAGE"
git -C "$ROOT_DIR" push origin "$BRANCH"

echo "Committed and pushed branch $BRANCH"
echo "GitHub Actions workflow '.github/workflows/jekyll.yml' will deploy Pages"
echo "Local build output: $BUILD_DIR"
