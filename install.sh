#!/usr/bin/env sh
# One-click installer for opencode-cli on LinPad iSH ARM64 Alpine.
# Usage:
#   ./install.sh                 # install binary into current system
#   ./install.sh --rootfs DIR    # build a fakefs image from the prebuilt rootfs
#   ./install.sh --from-local    # use artifacts next to this script
set -eu

REPO="starlight4you/oc-linpad"
RELEASE_TAG="${RELEASE_TAG:-latest}"
PREFIX="${PREFIX:-/usr/local}"
FROM_LOCAL=0
ROOTFS_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --rootfs) ROOTFS_DIR="$2"; shift 2 ;;
    --prefix) PREFIX="$2"; shift 2 ;;
    --from-local) FROM_LOCAL=1; shift ;;
    --release-tag) RELEASE_TAG="$2"; shift 2 ;;
    -h|--help)
      sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

arch="$(uname -m 2>/dev/null || echo unknown)"
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
  echo "warning: expected aarch64/arm64, got $arch" >&2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

asset_url() {
  # $1 = asset name
  if [ "$FROM_LOCAL" = "1" ]; then
    echo "$SCRIPT_DIR/$1"
  else
    if [ "$RELEASE_TAG" = "latest" ]; then
      echo "https://github.com/$REPO/releases/latest/download/$1"
    else
      echo "https://github.com/$REPO/releases/download/$RELEASE_TAG/$1"
    fi
  fi
}

download() {
  # $1 url, $2 dest
  if [ "$FROM_LOCAL" = "1" ]; then
    cp "$1" "$2"
  else
    echo "downloading $1"
    curl -fL --progress-bar -o "$2" "$1"
  fi
}

install_deps() {
  if command -v apk >/dev/null 2>&1; then
    apk add --no-cache libstdc++ sqlite 2>&1 | tail -3
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y libstdc++6 sqlite3
  else
    echo "no supported package manager found; ensure libstdc++.so.6 is installed" >&2
  fi
}

install_binary() {
  mkdir -p "$PREFIX/bin"
  tmp="$(mktemp)"
  download "$(asset_url opencode)" "$tmp"
  mv "$tmp" "$PREFIX/bin/opencode"
  chmod +x "$PREFIX/bin/opencode"
  echo "installed $PREFIX/bin/opencode"

  # cache
  cache_dir="${HOME:-/root}/.cache/opencode"
  mkdir -p "$cache_dir"
  tmp2="$(mktemp)"
  download "$(asset_url opencode-cache.tgz)" "$tmp2"
  tar -xzf "$tmp2" -C "${HOME:-/root}"
  rm -f "$tmp2"
  echo "installed opencode cache into $cache_dir"

  echo "--- verify ---"
  "$PREFIX/bin/opencode" --version
}

build_rootfs() {
  [ -n "$ROOTFS_DIR" ] || { echo "--rootfs requires a directory" >&2; exit 2; }
  mkdir -p "$ROOTFS_DIR"
  tmp="$(mktemp)"
  download "$(asset_url alpine-arm64-opencode-rootfs.tar.gz)" "$tmp"

  if [ "$FROM_LOCAL" = "1" ] && [ -x "$SCRIPT_DIR/fakefsify" ]; then
    FAKEFSIFY="$SCRIPT_DIR/fakefsify"
  elif command -v fakefsify >/dev/null 2>&1; then
    FAKEFSIFY="$(command -v fakefsify)"
  else
    # download fakefsify
    tmpf="$(mktemp)"
    download "$(asset_url fakefsify)" "$tmpf"
    chmod +x "$tmpf"
    FAKEFSIFY="$tmpf"
  fi

  "$FAKEFSIFY" "$tmp" "$ROOTFS_DIR"
  rm -f "$tmp"
  echo "fakefs image created at $ROOTFS_DIR"
  echo "run with: ish -f $ROOTFS_DIR /bin/sh"
}

if [ -n "$ROOTFS_DIR" ]; then
  build_rootfs
else
  install_deps
  install_binary
fi
