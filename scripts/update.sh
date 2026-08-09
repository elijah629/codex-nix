#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO="openai/codex"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_NIX="${SCRIPT_DIR}/../package.nix"
readonly PLATFORMS=(
  aarch64-apple-darwin
  x86_64-apple-darwin
  x86_64-unknown-linux-musl
  aarch64-unknown-linux-musl
)
WORK_DIR=""

cleanup() {
  if [[ -n "$WORK_DIR" && "$WORK_DIR" == "${TMPDIR:-/tmp}"/codex-update.* ]]; then
    rm -rf -- "$WORK_DIR"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: ./scripts/update.sh [--check | VERSION]

With no argument, update to latest Codex release.
EOF
}

current_version() {
  sed -n 's/^  version = "\([^"]*\)";.*/\1/p' "$PACKAGE_NIX"
}

latest_version() {
  local url
  if ! url=$(curl --fail --silent --show-error --location --head \
    --output /dev/null --write-out '%{url_effective}' \
    "https://github.com/${REPO}/releases/latest"); then
    return 1
  fi
  printf '%s\n' "${url##*/rust-v}"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

main() {
  local current target checksum_url checksums hashes_file output
  current=$(current_version)
  [[ -n "$current" ]] || fail "could not read current version from package.nix"

  case "${1:-}" in
    -h|--help)
      usage
      return
      ;;
    --check|'')
      target=$(latest_version) || fail "could not determine latest release"
      ;;
    -* )
      fail "unknown option: $1"
      ;;
    *)
      [[ $# -eq 1 ]] || fail "expected one version argument"
      target=$1
      ;;
  esac

  printf 'Current: %s\nLatest:  %s\n' "$current" "$target"
  [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] \
    || fail "invalid version: $target"

  if [[ "$current" == "$target" ]]; then
    printf 'Already up to date.\n'
    return
  fi
  if [[ "${1:-}" == "--check" ]]; then
    return
  fi

  WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/codex-update.XXXXXX")
  checksums="$WORK_DIR/SHA256SUMS"
  hashes_file="$WORK_DIR/hashes"
  output="$WORK_DIR/package.nix"
  checksum_url="https://github.com/${REPO}/releases/download/rust-v${target}/codex-package_SHA256SUMS"

  curl --fail --silent --show-error --location --retry 3 \
    --output "$checksums" "$checksum_url"

  local platform archive checksum hash
  for platform in "${PLATFORMS[@]}"; do
    archive="codex-package-${platform}.tar.gz"
    checksum=$(awk -v archive="$archive" '$2 == archive { print $1 }' "$checksums")
    [[ "$checksum" =~ ^[0-9a-f]{64}$ ]] \
      || fail "missing checksum for $archive"
    hash=$(nix hash convert --hash-algo sha256 --to sri "$checksum")
    printf '%s %s\n' "$platform" "$hash" >> "$hashes_file"
  done

  awk -v version="$target" '
    NR == FNR { hashes[$1] = $2; next }
    /^  version = "/ { sub(/"[^"]+"/, "\"" version "\"") }
    /^    "/ {
      platform = $1
      gsub(/"/, "", platform)
      if (platform in hashes) {
        sub(/= "[^"]*"/, "= \"" hashes[platform] "\"")
      }
    }
    { print }
  ' "$hashes_file" "$PACKAGE_NIX" > "$output"

  mv "$output" "$PACKAGE_NIX"
  chmod 0644 "$PACKAGE_NIX"
  printf 'Updated package.nix to %s. Run: nix build\n' "$target"
}

main "$@"
