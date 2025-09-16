#!/usr/bin/env bash
set -euo pipefail

log() {
    echo "$@" >&2
}

if [ $# -lt 1 ]; then
  log "Usage: $0 <os/arch> [image:tag]"
  log "Example: $0 linux/amd64 ubuntu:20.04"
  exit 1
fi

# Split os/arch argument (e.g. linux/amd64 → OS=linux, ARCH=amd64)
OS="${1%%/*}"
ARCH="${1#*/}"

# Default image if not provided
IMAGE="${2:-ubuntu:20.04}"

# Determine base cache directory
if [ -n "${XDG_CACHE_HOME:-}" ]; then
  BASECACHE="$XDG_CACHE_HOME"
elif [ -n "${HOME:-}" ]; then
  BASECACHE="$HOME/.cache"
else
  log "[ERROR] Neither XDG_CACHE_HOME nor HOME is set — cannot determine cache directory." >&2
  exit 1
fi
# TODO: --refresh option

HASH="$(echo -n "${OS}-${ARCH}-${IMAGE}" | sha256sum | cut -d' ' -f1)"
CACHEDIR="${BASECACHE}/patryk4815-kernel/${HASH}"

if [ "${3:-}" = "--refresh" ]; then
  rm -rf "$CACHEDIR"
fi

mkdir -p "$CACHEDIR"

TARFILE="${CACHEDIR}/image.tar"
SQFSFILE="${CACHEDIR}/image.squashfs"

# Skip if squashfs already exists
if [ -f "$SQFSFILE" ]; then
  log "[INFO] Found existing squashfs file: $SQFSFILE"
  log "[INFO] Skipping build."
  exit 0
fi

log "[INFO] Pulling image: $IMAGE for $OS/$ARCH"
skopeo copy \
  --insecure-policy \
  --override-os "$OS" \
  --override-arch "$ARCH" \
  "docker://$IMAGE" \
  "docker-archive:${TARFILE}" >&2

log "[INFO] Converting image to squashfs"
undocker "$TARFILE" - | tar2sqfs --no-xattr --compressor gzip --comp-extra level=3 "$SQFSFILE" >&2

log "[INFO] Removing temporary tarball"
rm -f "$TARFILE"

log "[INFO] Final squashfs file: $SQFSFILE"
echo $SQFSFILE
