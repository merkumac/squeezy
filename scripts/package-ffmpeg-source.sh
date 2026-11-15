#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?Usage: $0 SQUEEZY_VERSION}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

FFMPEG_VERSION="9.0.2"
RELEASE_DIR="${REPO_ROOT}/dist/${VERSION}"
PACKAGE="${RELEASE_DIR}/Squeezy-${VERSION}-FFmpeg-sources.tar.xz"

FFMPEG="${REPO_ROOT}/Tools/ffmpeg"
FFPROBE="${REPO_ROOT}/Tools/ffprobe"

for tool in "$FFMPEG" "$FFPROBE"; do
    [[ -x "$tool" ]] || {
        echo "Missing executable: $tool" >&2
        exit 1
    }
done

mkdir -p "$RELEASE_DIR"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf -- "$WORK_DIR"' EXIT

SOURCE_DIR="${WORK_DIR}/ffmpeg-source"
mkdir -p "$SOURCE_DIR"

"${SCRIPT_DIR}/build-ffmpeg.sh" --archive-only "${SOURCE_DIR}/ffmpeg-${FFMPEG_VERSION}.tar.xz"

"$FFMPEG" -buildconf > "${SOURCE_DIR}/BUILD.CONFIGURATION.txt"
"$FFMPEG" -L > "${SOURCE_DIR}/FFMPEG_LICENSE.txt"

cat > "${SOURCE_DIR}/README.txt" <<EOF
FFmpeg ${FFMPEG_VERSION} sources for Squeezy ${VERSION}.

Upstream: https://ffmpeg.oprg/
Source archive: ffmpeg-${FFMPEG_VERSION}.tar.xz

The source archive was verified against the FFmpeg release signature.
BUILD_CONFIGURATION.txt contains the configuration of the locally built
FFmpeg executable.

Squeezy invokes FFmpeg as a separate process.
Squeezy's own code is distributed under MIT License.
EOF

tar -C "$SOURCE_DIR" -cJf "$PACKAGE" .

echo "Created: $PACKAGE"
