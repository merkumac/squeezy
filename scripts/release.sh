#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?Usage: $0 VERSION /path/to/Squeezy.app}"
APP="${2:?Usage: $0 VERSION /path/to/Squeezy.app}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist/${VERSION}"

DMG="${DIST_DIR}/Squeezy-${VERSION}-arm64.dmg"
SOURCES="${DIST_DIR}/Squeezy-${VERSION}-FFmpeg-sources.tar.xz"

# verify input
[[ -d "$APP" ]] || {
    echo "Error: Squeezy.app not found: $APP" >&2
    exit 1
}

[[ -x "$APP/Contents/Helpers/ffmpeg" ]] || {
    echo "Error: bundled ffmpeg not found" >&2
    exit 1
}

[[ -x "$APP/Contents/Helpers/ffprobe" ]] || {
    echo "Error: bundled ffprobe not found" >&2
    exit 1
}

# verify app version
APP_VERSION=$(/usr/libexec/PlistBuddy \
    -c "Print CFBundleShortVersionString" \
    "$APP/Contents/Info.plist")

if [[ "$APP_VERSION" != "$VERSION" ]]; then
    echo "Error: app version $APP_VERSION != release version $VERSION" >&2
    exit 1
fi

# lets make sure we're not overwriting some existing release
if [[ -e "$DMG" || -e "$SOURCES" || -e "$DIST_DIR/SHA256SUMS.txt" ]]; then
    echo "Error: release artifacts already exist in $DIST_DIR" >&2
    exit 1
fi

# verify app's signature
codesign --verify --deep --strict "$APP"

"${SCRIPT_DIR}/build-dmg.sh" "$VERSION" "$APP"
"${SCRIPT_DIR}/package-ffmpeg-source.sh" "$VERSION"

[[ -s "$DMG" && -s "$SOURCES" ]] || {
    echo "Error: release artifacts are missing" >&2
    exit 1
}

hdiutil verify "$DMG"
tar -tJf "$SOURCES" >/dev/null

(
    cd "$DIST_DIR"
    shasum -a 256 "$(basename "$DMG")" "$(basename "$SOURCES")" > SHA256SUMS.txt
)

echo
echo "Release ${VERSION} packaged succesfully:"
ls -lh "$DMG" "$SOURCES" "$DIST_DIR/SHA256SUMS.txt"


