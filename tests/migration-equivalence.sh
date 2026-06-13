#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

assert_contains_file() {
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

assert_not_contains_file() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if rg -Fq "$needle" "$file"; then
    echo "断言失败: $message" >&2
    echo "  文件: $file" >&2
    echo "  不应包含: $needle" >&2
    exit 1
  fi
}

# Linux user meta 新架构：views + caps 字段
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "views" "Linux user meta 应含 views 字段"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "caps" "Linux user meta 应含 caps 字段"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"development/base\"" "Linux user meta 应在 views 中声明 development/base"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/workstation\"" "Linux user meta 应在 views 中声明 software/workstation"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"gaming/base\"" "Linux user meta 应在 views 中声明 gaming/base"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/firefox\"" "Linux user meta 应显式声明 firefox cap"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/vscode\"" "Linux user meta 应显式声明 vscode cap"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/gnucash\"" "Linux user meta 应显式声明 gnucash cap"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/logseq\"" "Linux user meta 应保留 logseq cap"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/ghidra\"" "Linux user meta 应显式声明逆向工具 cap"
assert_not_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/common\"" "Linux user meta 不应继续依赖 software/common"
assert_not_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"business/common\"" "Linux user meta 不应含已删除的 business/common"
assert_not_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"lifetime/common\"" "Linux user meta 不应含已删除的 lifetime/common"
assert_not_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"identity/rikki\"" "Linux user meta 不应含已删除的 identity/rikki cap"

# 旧的 per-system user 数据应仍存在
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"docker\"" "Linux user meta 应保留 docker 组"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"vboxusers\"" "Linux user meta 应保留 vboxusers 组"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"kvm\"" "Linux user meta 应保留 kvm 组"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"libvirt\"" "Linux user meta 应保留旧的 libvirt 组"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"libvirtd\"" "Linux user meta 应保留实际生效的 libvirtd 组"

assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/default.nix" "\"power-usage\"" "Linux host-local user 模块应保留 shell alias"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/default.nix" "powertop" "Linux host-local user 模块应保留便携工具包"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/default.nix" "pinentry.package" "Linux host-local user 模块应保留 gpg-agent 设置"

# identity 已迁移到 systems/shared/users/rikki/default.nix
assert_contains_file "$ROOT_DIR/systems/shared/users/rikki/default.nix" "\"Rikki\"" "共享身份模块应保留 Git 用户名"
assert_contains_file "$ROOT_DIR/systems/shared/users/rikki/default.nix" "\"rikki@member.fsf.org\"" "共享身份模块应保留 Git 邮箱"
assert_contains_file "$ROOT_DIR/systems/shared/users/rikki/default.nix" "\"3927D7F5365B0203\"" "共享身份模块应保留签名 key"

# 开发脚本仍在 caps/development/scripts cap 下
assert_contains_file "$ROOT_DIR/caps/development/scripts/user/scripts/workspace.sh" "workspace" "开发脚本应在 development/scripts cap 目录中"
assert_contains_file "$ROOT_DIR/caps/development/scripts/user/scripts/genprime.sh" "bash" "开发脚本应完整迁移"

# Darwin 主机也应有清晰的用户入口（新架构）
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "views" "Darwin user meta 应含 views 字段"
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "caps" "Darwin user meta 应含 caps 字段"
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "\"development/base\"" "Darwin user meta 应在 views 中声明 development/base"
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "\"software/workstation\"" "Darwin user meta 应在 views 中声明 software/workstation"
assert_not_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "\"identity/rikki\"" "Darwin user meta 不应含已删除的 identity/rikki cap"
assert_not_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "\"software/common\"" "Darwin user meta 不应继续依赖 software/common"
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/default.nix" "gnupg" "Darwin host-local user 模块应保留 gnupg 相关补充"

echo "Migration equivalence checks passed"
