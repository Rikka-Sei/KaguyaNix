#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f systems/shared/users/rikki/default.nix ] || { echo "FAIL: 缺共享身份文件"; exit 1; }
[ ! -d modules/identity ] || { echo "FAIL: modules/identity 仍存在"; exit 1; }
echo "PASS: identity-placement"
