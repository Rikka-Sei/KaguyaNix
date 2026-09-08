#!/usr/bin/env bash

# 错误路径与解析语义屏障：驱动 lib.kaguya 公开接口，
# 逐条锚定 docs/specs/kaguya/spec.md §5（错误模型）与 §7（异常与边界条件）。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$ROOT_DIR/tests/fixtures/error-paths"
VIEWS_DIR="$ROOT_DIR/tests/fixtures/views"
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

# 期望成功的求值，返回 JSON
nix_json() {
  cd "$ROOT_DIR" && nix eval "${NIX_FLAGS[@]}" --impure --json --expr "$1"
}

# 期望失败的求值，返回合并输出；表达式成功即失败
nix_fail() {
  set +e
  local out
  out="$(cd "$ROOT_DIR" && nix eval "${NIX_FLAGS[@]}" --impure --json --expr "$1" 2>&1)"
  local status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    echo "断言失败: 表达式应当失败却成功了" >&2
    echo "  表达式: $1" >&2
    exit 1
  fi
  printf '%s' "$out"
}

# 构造 buildPlanFromMeta 调用；capsDir 指向场景 fixture 根（capId 直接映射其下 <domain>/<name>）
plan_call() {
  local caps_dir="$1"
  local meta="$2"
  local select="$3"
  printf '(let flake = builtins.getFlake ("path:%s"); k = flake.outputs.lib.kaguya; in (k.buildPlanFromMeta { hostName = "err"; meta = %s; capsDir = "%s"; hardwareDir = "%s"; viewsDir = "%s"; })%s)' \
    "$ROOT_DIR" "$meta" "$caps_dir" "$FIX/hardware" "$VIEWS_DIR" "$select"
}

view_call() {
  local views="$1"
  local select="$2"
  printf '(let flake = builtins.getFlake ("path:%s"); k = flake.outputs.lib.kaguya; in (k.resolveViews { locale = "zh-CN"; viewsDir = "%s"; target = { platform = "linux"; arch = "x86_64"; }; facet = "system"; requested = %s; })%s)' \
    "$ROOT_DIR" "$VIEWS_DIR" "$views" "$select"
}

echo "── cap 错误路径 ────────────────────────────────────────────"

echo "T01: a/x 与 a/y 冲突 → cap.conflict"
out="$(nix_fail "$(plan_call "$FIX/caps/conflict" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "a/x" "a/y" ]; }' '')")"
assert_contains "$out" "冲突" "cap.conflict 应报冲突"
echo "  PASS"

echo "T02: b/loop 自依赖 → cap.cycle"
out="$(nix_fail "$(plan_call "$FIX/caps/selfreq" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "b/loop" ]; }' '')")"
assert_contains "$out" "依赖循环" "cap.cycle 应报依赖循环"
echo "  PASS"

echo "T03: c/user requires c/dep → 依赖先于依赖者"
out="$(nix_json "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "c/user" ]; }' '.systemCaps')")"
assert_eq "$out" '["c/dep","c/user"]' "依赖顺序应为 [c/dep, c/user]"
echo "  PASS"

echo "T04: d/e 缺 module.nix → cap.missingFacet"
out="$(nix_fail "$(plan_call "$FIX/caps/halfcap" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "d/e" ]; }' '')")"
assert_contains "$out" '缺少 `system` facet' "cap.missingFacet 应报缺 facet"
echo "  PASS"

echo "T05: f/g optionPath 为字符串 → cap.invalidMetaField"
out="$(nix_fail "$(plan_call "$FIX/caps/badpath" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "f/g" ]; }' '')")"
assert_contains "$out" '元数据字段 `optionPath` 非法' "cap.invalidMetaField 应报 optionPath 非法"
echo "  PASS"

echo "T06: g/h 仅 darwin、linux target → cap.unsupportedPlatform"
out="$(nix_fail "$(plan_call "$FIX/caps/darwinonly" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "g/h" ]; }' '')")"
assert_contains "$out" '不支持当前平台 `linux`' "cap.unsupportedPlatform 应报平台不支持"
echo "  PASS"

echo "T07: i/j 未声明支持表 → 等价空表，同样不支持"
out="$(nix_fail "$(plan_call "$FIX/caps/nosupport" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "i/j" ]; }' '')")"
assert_contains "$out" '不支持当前平台 `linux`' "缺省支持表应等价于全不支持"
echo "  PASS"

echo "T08: k/l 仅 aarch64、x86_64 target → cap.unsupportedArch"
out="$(nix_fail "$(plan_call "$FIX/caps/archonly" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "k/l" ]; }' '')")"
assert_contains "$out" '不支持当前架构 `x86_64`' "cap.unsupportedArch 应报架构不支持"
echo "  PASS"

echo "T09: 非法 capId（无斜杠）→ cap.invalidId"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; caps = [ "no-slash" ]; }' '')")"
assert_contains "$out" '必须是 `<domain>/<name>` 形式' "cap.invalidId 应报标识不合法"
echo "  PASS"

echo "── 硬件与宿主机 meta 错误路径 ──────────────────────────────"

echo "T10: hardware = ghost → hardware.unknown"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "ghost"; }' '')")"
assert_contains "$out" "未知硬件配置" "hardware.unknown 应报未知硬件"
echo "  PASS"

echo "T11: hardware = nometa → hardware.missingMeta"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "nometa"; }' '')")"
assert_contains "$out" '缺少 `meta.nix`' "hardware.missingMeta 应报缺 meta.nix"
echo "  PASS"

echo "T12: hardware = noconfig → hardware.missingConfiguration"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "noconfig"; }' '')")"
assert_contains "$out" '缺少 `configuration.nix`' "hardware.missingConfiguration 应报缺 configuration.nix"
echo "  PASS"

echo "T13: meta 缺 hardware 字段 → node.missingField"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; }' '')")"
assert_contains "$out" '缺少必填字段 `hardware`' "node.missingField 应报缺 hardware"
echo "  PASS"

echo "T14: target 为字符串 → node.invalidType"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = "linux"; hardware = "good"; }' '')")"
assert_contains "$out" "类型错误" "node.invalidType 应报类型错误"
echo "  PASS"

echo "T15: shell = powershell → node.invalidEnum"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; users.z.shell = "powershell"; }' '')")"
assert_contains "$out" "取值非法" "node.invalidEnum 应报枚举非法"
echo "  PASS"

echo "T16: darwin target + linux-only 硬件 → hardware.unsupportedPlatform"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "darwin"; arch = "aarch64"; }; hardware = "good"; }' '')")"
assert_contains "$out" '不支持当前平台 `darwin`' "hardware.unsupportedPlatform 应报平台不支持"
echo "  PASS"

echo "T17: darwin x86_64 + aarch64-only 硬件 → hardware.unsupportedArch"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "darwin"; arch = "x86_64"; }; hardware = "good-darwin"; }' '')")"
assert_contains "$out" '不支持当前架构 `x86_64`' "hardware.unsupportedArch 应报架构不支持"
echo "  PASS"

echo "── 用户实例语义 ────────────────────────────────────────────"

echo "T18: enable = false → caps 解析为空"
out="$(nix_json "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; users.x = { enable = false; caps = [ "c/dep" ]; }; }' '.users.x.caps')")"
assert_eq "$out" '[]' "禁用用户的 caps 应为空列表"
echo "  PASS"

echo "T19: 用户缺省值 → stateVersion 24.05、homeDirectory /home/y、shell bash"
out="$(nix_json "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; users.y = {}; }' '.users.y')")"
assert_contains "$out" '"24.05"' "stateVersion 缺省应为 24.05"
assert_contains "$out" '"/home/y"' "homeDirectory 缺省应为 /home/y"
assert_contains "$out" '"bash"' "shell 缺省应为 bash"
echo "  PASS"

echo "T20: darwin 用户缺省 homeDirectory → /Users/y"
out="$(nix_json "$(plan_call "$FIX/caps/order" '{ target = { platform = "darwin"; arch = "aarch64"; }; hardware = "good-darwin"; users.y = {}; }' '.users.y.homeDirectory')")"
assert_eq "$out" '"/Users/y"' "darwin 缺省 homeDirectory 应为 /Users/y"
echo "  PASS"

echo "── 视图错误路径与顺序 ──────────────────────────────────────"

echo "T21: 非法 viewId → view.invalidId"
out="$(nix_fail "$(view_call '["bad"]' '')")"
assert_contains "$out" "不合法" "view.invalidId 应报标识不合法"
echo "  PASS"

echo "T22: m/missing 无 system.nix → view.missingFacet"
out="$(nix_fail "$(view_call '["m/missing"]' '')")"
assert_contains "$out" '缺少 `system` facet' "view.missingFacet 应报缺 facet 文件"
echo "  PASS"

echo "T23: q/archonly 仅 aarch64 → view.unsupportedArch"
out="$(nix_fail "$(view_call '["q/archonly"]' '')")"
assert_contains "$out" '不支持当前架构 `x86_64`' "view.unsupportedArch 应报架构不支持"
echo "  PASS"

echo "T24: d/outer includes d/inner → views 为收集完成序（inner 先于 outer）"
out="$(nix_json "$(view_call '["d/outer"]' '.views')")"
assert_eq "$out" '["d/inner","d/outer"]' "views 顺序应为后序 [d/inner, d/outer]"
echo "  PASS"

echo "── 本地化与公开工具 ────────────────────────────────────────"

echo "T25: locale 未注册 → 回退 zh-CN 输出中文错误"
out="$(nix_fail "$(plan_call "$FIX/caps/order" '{ target = { platform = "linux"; arch = "x86_64"; }; hardware = "good"; locale = "xx-XX"; caps = [ "c/ghost" ]; }' '')")"
assert_contains "$out" "未知 cap" "locale 回退后仍应输出中文错误"
echo "  PASS"

echo "T26: 未注册错误码 → fallbackRenderer 输出 Kaguya error"
out="$(cd "$ROOT_DIR" && nix eval "${NIX_FLAGS[@]}" --impure --raw --expr \
  '(let flake = builtins.getFlake ("path:'"$ROOT_DIR"'"); k = flake.outputs.lib.kaguya; in k.renderError "zh-CN" { code = "test.nonexistent"; })')"
assert_contains "$out" "Kaguya error" "fallbackRenderer 应输出 Kaguya error 前缀"
echo "  PASS"

echo "T27: mergeAttrsets 同路径叶子值后写胜出"
out="$(cd "$ROOT_DIR" && nix eval "${NIX_FLAGS[@]}" --impure --json --expr \
  '(let flake = builtins.getFlake ("path:'"$ROOT_DIR"'"); k = flake.outputs.lib.kaguya; in k.mergeAttrsets [ { a.b = 1; } { a.b = 2; } ])')"
assert_eq "$out" '{"a":{"b":2}}' "mergeAttrsets 应后写胜出"
echo "  PASS"

echo ""
echo "error-paths tests passed"
