#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLAKE_REF="path:$ROOT_DIR"
NIX_FLAGS=(
  --extra-experimental-features "nix-command flakes"
  --no-warn-dirty
)

assert_eq() {
  local actual="$1" expected="$2" msg="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: $msg"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    exit 1
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: $msg"
    echo "  expected to contain: $needle"
    echo "  actual: $haystack"
    exit 1
  fi
}

# run a nix --impure --expr that should SUCCEED, return JSON
nix_expr_json() {
  cd "$ROOT_DIR" && nix eval "${NIX_FLAGS[@]}" --impure --json --expr "$1"
}

# run a nix --impure --expr that should FAIL, return combined stdout+stderr
nix_expr_fail() {
  set +e
  local out
  out="$(cd "$ROOT_DIR" && nix eval "${NIX_FLAGS[@]}" --show-trace --impure --json --expr "$1" 2>&1)"
  local status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    echo "FAIL: expected nix eval to fail but it succeeded"
    echo "  expr: $1"
    echo "  output: $out"
    exit 1
  fi
  echo "$out"
}

VIEWS_DIR="$ROOT_DIR/tests/fixtures/views"

# ── Test 1: normal expand ─────────────────────────────────────────────────────
echo "Test 1: a/base → caps 含 x/leaf"
result="$(nix_expr_json '
  let
    flake = builtins.getFlake ("path:'"$ROOT_DIR"'");
    rv = flake.outputs.lib.kaguya.resolveViews {
      locale = "zh-CN";
      viewsDir = '"$VIEWS_DIR"';
      target = { platform = "linux"; arch = "x86_64"; };
      facet = "system";
      requested = ["a/base"];
    };
  in rv
')"
assert_contains "$result" '"x/leaf"' "a/base 应贡献 x/leaf cap"
echo "  PASS"

# ── Test 2: unknown view → 中文报错 ───────────────────────────────────────────
echo "Test 2: a/missing → 未知 view 报错"
err="$(nix_expr_fail '
  let
    flake = builtins.getFlake ("path:'"$ROOT_DIR"'");
  in flake.outputs.lib.kaguya.resolveViews {
    locale = "zh-CN";
    viewsDir = '"$VIEWS_DIR"';
    target = { platform = "linux"; arch = "x86_64"; };
    facet = "system";
    requested = ["a/missing"];
  }
')"
assert_contains "$err" "未知 view" "未知 view 应报中文错误"
echo "  PASS"

# ── Test 3: cycle → 循环报错 ──────────────────────────────────────────────────
echo "Test 3: c1/base ↔ c2/base 互相 include → 循环报错"
err="$(nix_expr_fail '
  let
    flake = builtins.getFlake ("path:'"$ROOT_DIR"'");
  in flake.outputs.lib.kaguya.resolveViews {
    locale = "zh-CN";
    viewsDir = '"$VIEWS_DIR"';
    target = { platform = "linux"; arch = "x86_64"; };
    facet = "system";
    requested = ["c1/base"];
  }
')"
assert_contains "$err" "循环" "循环依赖应报中文循环错误"
echo "  PASS"

# ── Test 4: unsupported platform → 报错 ──────────────────────────────────────
echo "Test 4: p/base 仅支持 darwin，linux target → 不支持报错"
err="$(nix_expr_fail '
  let
    flake = builtins.getFlake ("path:'"$ROOT_DIR"'");
  in flake.outputs.lib.kaguya.resolveViews {
    locale = "zh-CN";
    viewsDir = '"$VIEWS_DIR"';
    target = { platform = "linux"; arch = "x86_64"; };
    facet = "system";
    requested = ["p/base"];
  }
')"
assert_contains "$err" "不支持" "不支持的平台应报错"
echo "  PASS"

echo ""
echo "view-graph tests passed"
