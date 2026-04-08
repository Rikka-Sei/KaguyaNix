#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

deploy_file="$ROOT_DIR/parts/deploy.nix"

if rg -Fq "x86_64-linux.activate.nixos" "$deploy_file"; then
  echo "断言失败: deploy 不应再把激活架构硬编码为 x86_64-linux" >&2
  exit 1
fi

if ! rg -Fq 'builtins.currentSystem' "$deploy_file"; then
  echo "断言失败: deploy 应根据当前机器系统选择 deploy-rs activate 库" >&2
  exit 1
fi

echo "Deploy smoke tests passed"
