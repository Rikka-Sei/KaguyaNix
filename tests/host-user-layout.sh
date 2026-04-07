#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

assert_exists() {
  local path="$1"
  local message="$2"

  if [[ ! -e "$path" ]]; then
    echo "断言失败: $message" >&2
    echo "  缺少: $path" >&2
    exit 1
  fi
}

assert_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if ! rg -Fq "$needle" "$file"; then
    echo "断言失败: $message" >&2
    echo "  文件: $file" >&2
    echo "  期望包含: $needle" >&2
    exit 1
  fi
}

assert_exists "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "Linux host 应保留清晰的用户实例数据入口"
assert_exists "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/default.nix" "Linux host 应保留清晰的用户补充模块入口"
assert_exists "$ROOT_DIR/systems/laptop-mbp2019/users/rikki/meta.nix" "Darwin host 应保留清晰的用户实例数据入口"
assert_exists "$ROOT_DIR/systems/laptop-mbp2019/users/rikki/default.nix" "Darwin host 应保留清晰的用户补充模块入口"

assert_contains "$ROOT_DIR/systems/laptop-asus-tx4-personal/meta.nix" "import ./users/rikki/meta.nix" "Linux host 的 meta 应显式导入用户数据"
assert_contains "$ROOT_DIR/systems/laptop-asus-tx4-personal/default.nix" "./users/rikki/default.nix" "Linux host 的默认模块应显式导入用户补充模块"
assert_contains "$ROOT_DIR/systems/laptop-mbp2019/meta.nix" "import ./users/rikki/meta.nix" "Darwin host 的 meta 应显式导入用户数据"
assert_contains "$ROOT_DIR/systems/laptop-mbp2019/default.nix" "./users/rikki/default.nix" "Darwin host 的默认模块应显式导入用户补充模块"

echo "Host user layout checks passed"
