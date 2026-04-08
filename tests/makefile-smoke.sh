#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

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

list_output="$(
  cd "$ROOT_DIR" &&
    make list
)"

assert_contains "$list_output" "laptop-asus-tx4-personal" "make list 应列出 Linux 系统"
assert_contains "$list_output" "laptop-mbpM2" "make list 应列出 Darwin 系统"

check_plan="$(
  cd "$ROOT_DIR" &&
    make -n check laptop-asus-tx4-personal
)"

assert_contains "$check_plan" "--extra-experimental-features 'nix-command flakes'" "make check 应注入 nix-command / flakes 特性参数"
assert_contains "$check_plan" "path:./#nixosConfigurations.laptop-asus-tx4-personal.config.system.build.toplevel" "make check 应使用新的 path flake 引用"

use_plan="$(
  cd "$ROOT_DIR" &&
    make -n use laptop-mbpM2
)"

assert_contains "$use_plan" "path:./#darwinConfigurations" "make use 应使用新的 path flake 引用检测 Darwin 系统"
assert_contains "$use_plan" "nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake path:./#\$TARGET" "make use 应通过 nix run 调用 Darwin 重建入口"

if [[ "$use_plan" == *"sudo darwin-rebuild"* ]]; then
  echo "断言失败: make use 不应继续直接依赖裸 darwin-rebuild 命令" >&2
  exit 1
fi

alias_plan="$(
  cd "$ROOT_DIR" &&
    make -n laptop-mbpM2
)"

assert_contains "$alias_plan" '$(MAKE) use laptop-mbpM2' "直接执行 make <system-name> 应转发到 make use <system-name>"

echo "Makefile smoke tests passed"
