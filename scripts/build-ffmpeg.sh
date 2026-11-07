#!/usr/bin/env bash

set -euo pipefail

readonly FFMPEG_VERSION="9.0.2"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly TOOLS_DIR="${REPO_ROOT}/Tools"

readonly WORK_DIR="/tmp/squeezy-ffmpeg-build"
readonly ARCHIVE="ffmpeg-${FFMPEG_VERSION}.tar.xz"
readonly SOURCE_URL="https://ffmpeg.org/releases/${ARCHIVE}"

mkdir -p "$WORK_DIR"

BUILD_DIR="$(mktemp -d "${WORK_DIR}/build.XXXXXXXX")"
trap 'rm -rf -- "$BUILD_DIR"' EXIT

# Download ffmpeg and key for verification
curl --fail --location --show-error --output "${BUILD_DIR}/${ARCHIVE}" "${SOURCE_URL}"
curl --fail --location --show-error --output "${BUILD_DIR}/${ARCHIVE}.asc" "${SOURCE_URL}.asc"

readonly EXPECTED_FINGERPRINT="FCF986EA15E6E293A5644F10B4322F04D67658D8"
readonly GPG_HOME="${BUILD_DIR}/gnupg"

mkdir -m 700 "$GPG_HOME"

curl --fail --location --show-error --output "${BUILD_DIR}/ffmpeg-devel.asc" "https://ffmpeg.org/ffmpeg-devel.asc"

actual_fingerprint="$(
    gpg --homedir "$GPG_HOME" --show-keys --with-colons \
        "${BUILD_DIR}/ffmpeg-devel.asc" | awk -F: '$1 == "fpr" { print $10; exit }'
)"

if [[ "$actual_fingerprint" != "$EXPECTED_FINGERPRINT" ]]; then
    echo "ERROR: FFmpeg signing key fingerprint mismatch" >&2
    exit 1
fi

gpg --homedir "$GPG_HOME" --import "${BUILD_DIR}/ffmpeg-devel.asc"
gpg --homedir "$GPG_HOME" --verify "${BUILD_DIR}/${ARCHIVE}.asc" "${BUILD_DIR}/${ARCHIVE}"

tar -xf "${BUILD_DIR}/${ARCHIVE}" -C "$BUILD_DIR"

readonly SOURCE_DIR="${BUILD_DIR}/ffmpeg-${FFMPEG_VERSION}"

cd "$SOURCE_DIR"

./configure \
    --prefix="${BUILD_DIR}/install" \
    --arch=arm64 \
    --enable-static \
    --disable-shared \
    --disable-debug \
    --disable-doc \
    --disable-ffplay \
    --disable-network \
    --disable-autodetect \
    --disable-avdevice \
    --disable-gpl \
    --disable-version3 \
    --disable-everything \
    --enable-videotoolbox \
    --enable-audiotoolbox \
    --enable-decoder=h264,hevc,aac \
    --enable-encoder=hevc_videotoolbox,aac \
    --enable-demuxer=mov,matroska \
    --enable-muxer=mp4 \
    --enable-parser=h264,hevc,aac \
    --enable-protocol=file,pipe \
    --enable-filter=scale,format,aresample,anull,null

make -j"$(sysctl -n hw.ncpu)"
make install

readonly INSTALL_BIN="${BUILD_DIR}/install/bin"

for tool in ffmpeg ffprobe; do
    if [[ ! -x "${INSTALL_BIN}/${tool}" ]]; then
        echo "ERROR: ${tool} was not build" >&2
        exit 1
    fi
done

mkdir -p "$TOOLS_DIR"

for tool in ffmpeg ffprobe; do
    cp "${INSTALL_BIN}/${tool}" "${TOOLS_DIR}/${tool}"
done

echo "Squeezy FFmpeg build completed."


