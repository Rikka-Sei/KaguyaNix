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

# 旧的系统 user profiles 应转成新的 user capabilities
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"development/base\"" "Linux user meta 应映射 development profile"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/workstation\"" "Linux user meta 应将桌面软件基线映射为 workstation capability"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/network-access\"" "Linux user meta 应显式声明网络接入软件 capability"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/learning\"" "Linux user meta 应显式声明学习软件 capability"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/logseq\"" "Linux user meta 应保留 logseq capability"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/reverse-engineering\"" "Linux user meta 应显式声明逆向软件 capability"
assert_not_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"software/common\"" "Linux user meta 不应继续依赖 software/common"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"gaming/base\"" "Linux user meta 应映射 gaming profile"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"business/common\"" "Linux user meta 应映射 business profile"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"lifetime/common\"" "Linux user meta 应映射 lifetime profile"

# 旧的 per-system user 数据应仍存在
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"docker\"" "Linux user meta 应保留 docker 组"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"vboxusers\"" "Linux user meta 应保留 vboxusers 组"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"kvm\"" "Linux user meta 应保留 kvm 组"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"libvirt\"" "Linux user meta 应保留旧的 libvirt 组"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/meta.nix" "\"libvirtd\"" "Linux user meta 应保留实际生效的 libvirtd 组"

assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/default.nix" "\"power-usage\"" "Linux host-local user 模块应保留 shell alias"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/default.nix" "powertop" "Linux host-local user 模块应保留便携工具包"
assert_contains_file "$ROOT_DIR/systems/laptop-asus-tx4-personal/users/rikki/default.nix" "pinentry.package" "Linux host-local user 模块应保留 gpg-agent 设置"

# 旧 development profile 中的 identity 与脚本应迁到 capability
assert_contains_file "$ROOT_DIR/modules/identity/rikki/user/module.nix" "\"Rikki\"" "identity capability 应保留 Git 用户名"
assert_contains_file "$ROOT_DIR/modules/identity/rikki/user/module.nix" "\"rikki@member.fsf.org\"" "identity capability 应保留 Git 邮箱"
assert_contains_file "$ROOT_DIR/modules/identity/rikki/user/module.nix" "\"3927D7F5365B0203\"" "identity capability 应保留签名 key"
assert_contains_file "$ROOT_DIR/modules/development/base/user/scripts/workspace.sh" "workspace" "开发脚本应迁移到 capability 目录"
assert_contains_file "$ROOT_DIR/modules/development/base/user/scripts/genprime.sh" "bash" "开发脚本应完整迁移"

# Darwin 主机也应有清晰的用户入口
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "\"identity/rikki\"" "Darwin user meta 应保留 identity capability"
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "\"software/workstation\"" "Darwin user meta 应声明桌面软件基线 capability"
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "\"software/network-access\"" "Darwin user meta 应声明网络接入软件 capability"
assert_not_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/meta.nix" "\"software/common\"" "Darwin user meta 不应继续依赖 software/common"
assert_contains_file "$ROOT_DIR/systems/laptop-mbpM2/users/rikki/default.nix" "gnupg" "Darwin host-local user 模块应保留 gnupg 相关补充"

echo "Migration equivalence checks passed"
