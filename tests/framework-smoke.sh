#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLAKE_REF="path:$ROOT_DIR"
NIX_FLAGS=(
  --extra-experimental-features
  "nix-command flakes"
)

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "断言失败: $message" >&2
    echo "  期望: $expected" >&2
    echo "  实际: $actual" >&2
    exit 1
  fi
}

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

linux_platform="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --raw "$FLAKE_REF#nixosConfigurations.laptop-asus-tx4-personal.config.kaguya.buildPlan.target.platform"
)"
assert_eq "$linux_platform" "linux" "Linux host 应暴露新的 buildPlan 平台信息"

linux_arch="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --raw "$FLAKE_REF#nixosConfigurations.laptop-asus-tx4-personal.config.kaguya.buildPlan.target.arch"
)"
assert_eq "$linux_arch" "x86_64" "Linux host 应暴露新的 buildPlan 架构信息"

darwin_platform="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --raw "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.kaguya.buildPlan.target.platform"
)"
assert_eq "$darwin_platform" "darwin" "Darwin host 应暴露新的 buildPlan 平台信息"

darwin_arch="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --raw "$FLAKE_REF#darwinConfigurations.laptop-mbpM2.config.kaguya.buildPlan.target.arch"
)"
assert_eq "$darwin_arch" "aarch64" "Darwin host 应暴露新的 buildPlan 架构信息"

linux_capabilities="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#nixosConfigurations.laptop-asus-tx4-personal.config.kaguya.buildPlan.systemCapabilities"
)"
assert_contains "$linux_capabilities" "\"services/docker\"" "Linux host 应包含 system capability 展开结果"

rikki_capabilities="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --json "$FLAKE_REF#nixosConfigurations.laptop-asus-tx4-personal.config.kaguya.buildPlan.users.rikki.capabilities"
)"
assert_contains "$rikki_capabilities" "\"identity/rikki\"" "用户 capability 应出现在 buildPlan 中"

set +e
invalid_output="$(
  cd "$ROOT_DIR" &&
    nix eval "${NIX_FLAGS[@]}" --show-trace --impure --json --expr '
      let
        flake = builtins.getFlake ("path:" + toString ./.);
        plan = flake.outputs.lib.kaguya.buildPlanFromMeta {
          hostName = "invalid-capability";
          meta = import ./tests/fixtures/invalid-capability.nix;
          modulesDir = ./modules;
          hardwareDir = ./hardware;
        };
      in
      plan.systemCapabilities
    ' 2>&1
)"
invalid_status=$?
set -e

if [[ "$invalid_status" -eq 0 ]]; then
  echo "断言失败: 非法 capability 测试应当失败" >&2
  exit 1
fi

assert_contains "$invalid_output" "未知 capability" "非法 capability 应返回中文错误"

echo "Framework smoke tests passed"
