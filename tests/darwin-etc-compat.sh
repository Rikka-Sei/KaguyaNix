#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLAKE_REF="path:$ROOT_DIR"
NIX_FLAGS=(
  --extra-experimental-features
  "nix-command flakes"
)

BASHRC_HASH="8b5e3466922d1ae34bc145e21c7e53e7329a7a7b58b148b436bd954d5e651ac3"
ZSHRC_HASH="4d1ab5704f9d167a042fecac0d056c8a79a8ebd71e032d3489536c8db9ffe3e0"
ZPROFILE_HASH="f320016e2cf13573731fbee34f9fe97ba867dd2a31f24893d3120154e9306e92"

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    echo "断言失败: $message" >&2
    echo "  期望包含: $needle" >&2
    echo "  实际输出: $haystack" >&2
    exit 1
  fi
}

bash_hashes="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.environment.etc.\"bashrc\".knownSha256Hashes"
)"
assert_contains "$bash_hashes" "\"$BASHRC_HASH\"" "Darwin host 应把当前 /etc/bashrc 哈希加入 knownSha256Hashes"

zsh_hashes="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.environment.etc.\"zshrc\".knownSha256Hashes"
)"
assert_contains "$zsh_hashes" "\"$ZSHRC_HASH\"" "Darwin host 应把当前 /etc/zshrc 哈希加入 knownSha256Hashes"

zprofile_hashes="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.environment.etc.\"zprofile\".knownSha256Hashes"
)"
assert_contains "$zprofile_hashes" "\"$ZPROFILE_HASH\"" "Darwin host 应把当前 /etc/zprofile 哈希加入 knownSha256Hashes"

echo "Darwin etc compatibility tests passed"
