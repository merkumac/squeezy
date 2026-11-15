#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?Usage: $0 VERSION /path/to/Squeezy.app}"
APP="${2:?Usage: $0 /path/to/Squeezy.app}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist/${VERSION}"
DMG="${DIST_DIR}/Squeezy-${VERSION}-arm64.dmg"

if [[ ! -d "$APP" ]]; then
    echo "Error: application not found: $APP" >&2
    exit 1
fi

mkdir -p "$DIST_DIR"

WORK_DIR="$(mktemp -d)"
STAGING="$WORK_DIR/Squeezy"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$STAGING"

ditto "$APP" "$STAGING/Squeezy.app"
ln -s /Applications "$STAGING/Applications"

mkdir -p "$STAGING/Licenses"

cp "$REPO_ROOT/LICENSE" "$STAGING/Licenses/"
cp "$REPO_ROOT/THIRD_PARTY_NOTICES.md" "$STAGING/Licenses/"
cp "$REPO_ROOT/licenses/FFmpeg-LGPL-2.1.txt" "$STAGING/Licenses/"

if [[ -e "$DMG" ]]; then
    echo "Error: DMG already exists: $DMG" >&2
    exit 1
fi

diskutil image create from --format UDZO "$STAGING" "$DMG"

echo "Created: $DMG"
