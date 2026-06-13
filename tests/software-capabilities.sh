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
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#nixosConfigurations.laptop-asus-tx4-personal.config.kaguya.buildPlan.users.rikki.caps"
)"
assert_contains "$linux_caps" "\"software/firefox\"" "Linux 用户应启用 firefox cap"
assert_contains "$linux_caps" "\"software/vscode\"" "Linux 用户应启用 vscode cap"
assert_contains "$linux_caps" "\"software/gnucash\"" "Linux 用户应启用 gnucash cap"
assert_contains "$linux_caps" "\"software/logseq\"" "Linux 用户应继续显式启用 logseq cap"
assert_contains "$linux_caps" "\"software/ghidra\"" "Linux 用户应启用逆向工具 cap"
assert_not_contains "$linux_caps" "\"software/common\"" "Linux 用户不应继续启用 software/common cap"

darwin_caps="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.kaguya.buildPlan.users.rikki.caps"
)"
assert_contains "$darwin_caps" "\"core/user-cli\"" "Darwin 用户应启用 core/user-cli cap"
assert_contains "$darwin_caps" "\"software/spotify\"" "Darwin 用户应启用 spotify cap"
assert_contains "$darwin_caps" "\"software/thunderbird\"" "Darwin 用户应经 view 获得 thunderbird cap"
assert_not_contains "$darwin_caps" "\"software/firefox\"" "Darwin 用户不应含 firefox cap"
assert_not_contains "$darwin_caps" "\"software/vscode\"" "Darwin 用户不应含 vscode cap"
assert_not_contains "$darwin_caps" "\"software/logseq\"" "Darwin 用户不应默认启用 logseq cap"
assert_not_contains "$darwin_caps" "\"software/common\"" "Darwin 用户不应继续启用 software/common cap"

darwin_packages="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.home-manager.users.rikki.home.packages"
)"
assert_not_contains "$darwin_packages" "logseq" "Darwin 用户环境不应继续包含 logseq 包"
assert_contains "$darwin_packages" "thunderbird" "Darwin 用户环境应含通信软件包"
assert_not_contains "$darwin_packages" "firefox" "Darwin 用户环境不应含 firefox 包"
assert_not_contains "$darwin_packages" "vscode" "Darwin 用户环境不应含 vscode 包"
assert_contains "$darwin_packages" "spotify" "Darwin 用户环境应含 spotify 包"
assert_contains "$darwin_packages" "gemini-cli" "Darwin 用户环境应含开发命令行工具"
assert_contains "$darwin_packages" "treefmt" "Darwin 用户环境应含开发格式化工具"

linux_packages="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#nixosConfigurations.laptop-asus-tx4-personal.config.home-manager.users.rikki.home.packages"
)"
assert_contains "$linux_packages" "mindustry" "Linux 用户环境应继续包含游戏软件包"
assert_contains "$linux_packages" "ddnet" "Linux 用户环境应继续包含 Linux 游戏软件包"
assert_contains "$linux_packages" "gnome-software" "Linux 用户环境应继续包含桌面工具软件包"
assert_contains "$linux_packages" "signal-desktop" "Linux 用户环境应继续包含通信软件包"
assert_contains "$linux_packages" "vscode" "Linux 用户环境应继续包含 vscode"
assert_contains "$linux_packages" "firefox" "Linux 用户环境应包含 firefox"
assert_contains "$linux_packages" "gnucash" "Linux 用户环境应包含 gnucash"
assert_contains "$linux_packages" "vlc" "Linux 用户环境应包含 vlc（迁移不得丢包，回归守卫）"
assert_contains "$linux_packages" "tor-browser" "Linux 用户环境应包含 tor-browser（迁移不得丢包，回归守卫）"

echo "Software capability tests passed"
