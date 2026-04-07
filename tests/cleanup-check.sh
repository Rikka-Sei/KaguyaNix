#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

assert_not_exists() {
  local path="$1"
  local message="$2"

  if [[ -e "$path" ]]; then
    echo "断言失败: $message" >&2
    echo "  不应存在: $path" >&2
    exit 1
  fi
}

assert_rg_empty() {
  local pattern="$1"
  local message="$2"
  local output

  output="$(
    cd "$ROOT_DIR" &&
      rg -n "$pattern" README.md AGENTS.md Makefile
  )" || true

  if [[ -n "$output" ]]; then
    echo "断言失败: $message" >&2
    echo "$output" >&2
    exit 1
  fi
}

assert_not_exists "$ROOT_DIR/users" "旧的 users 目录应被完全清理"

assert_rg_empty "systemConfig = \\{|users/\\{username\\}/base\\.nix|users/\\{username\\}/profiles|users/\\{username\\}/per-system|systems/\\$\\{name\\}\\.nix|laptop-asus-tx4-personal\\.nix" "主文档中不应继续保留旧架构示例或旧路径说明"

echo "Cleanup checks passed"
