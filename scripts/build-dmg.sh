#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
APP="${1:?Usage: $0 /path/to/Squeezy.app}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist"
DMG="${DIST_DIR}/Squeezy-${VERSION}-arm64.dmg"

if [[ ! -d "$APP" ]]; then
    echo "Error: application not found: $APP" >&2
    exit 1
fi

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

mkdir -p "$DIST_DIR"

ditto "$APP" "$STAGING/Squeezy.app"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG"

diskutil image create from --format UDZO "$STAGING" "$DMG"

echo "Created: $DMG"
