#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLAKE_REF="path:$ROOT_DIR"
NIX_FLAGS=(
  --extra-experimental-features
  "nix-command flakes"
)

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

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    echo "断言失败: $message" >&2
    echo "  不应包含: $needle" >&2
    echo "  实际输出: $haystack" >&2
    exit 1
  fi
}

linux_caps="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#nixosConfigurations.laptop-asus-tx4-personal.config.kaguya.buildPlan.users.rikki.capabilities"
)"
assert_contains "$linux_caps" "\"software/logseq\"" "Linux 用户应继续显式启用 logseq capability"

darwin_caps="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.kaguya.buildPlan.users.rikki.capabilities"
)"
assert_not_contains "$darwin_caps" "\"software/logseq\"" "Darwin 用户不应默认启用 logseq capability"

darwin_packages="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.home-manager.users.rikki.home.packages"
)"
assert_not_contains "$darwin_packages" "logseq" "Darwin 用户环境不应继续包含 logseq 包"

echo "Software capability tests passed"
