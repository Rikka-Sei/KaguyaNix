# Cap 与 View 架构迁移 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 KaguyaNix 重构为「`modules/` 只放叶子 cap、`views/` 放纯数据聚合、身份回到 `systems/`」，并将英文代码标识 `capability` 统一缩短为 `cap`、聚合概念定名 `view`。

**Architecture:** 先 additive 建好全部新叶子 cap、view 与共享身份文件（不触动现有构建）；再一次性切换框架（加 view 解析 + `capability→cap` 改名）并迁移宿主/用户元数据、删除旧模块（因无兼容别名，字段改名必须与元数据迁移同块完成）；最后补测试与文档。

**Tech Stack:** Nix, flake-parts, Home Manager, nix-darwin, NixOS, Bash 测试脚本

设计依据：`docs/superpowers/specs/2026-06-11-cap-view-architecture-design.md`。

---

## 文件结构

### 框架（改名 + 新增 view 解析）

- `lib/capabilityGraph.nix` → `lib/capGraph.nix`：导出名 `capabilityGraph`→`capGraph`；`resolveCapabilities`→`resolveCaps`、`loadFacetMeta`→`loadCapFacet`、`parseCapabilityId`→`parseCapId`、`capabilityDir`→`capDir`；新增 `parseViewId`/`viewDir`/`loadViewFacet`/`resolveViews`；`buildPlanFromMeta` 增加 `views`/`caps` 字段解析与 view→cap 合流。
- `lib/errors.nix`：`capability.*`→`cap.*`；新增 `view.*`。
- `parts/systems.nix`：`graph = extendedLib.capGraph`；`mkPlan` 传 `viewsDir = ../views`；`buildPlan` 字段改名（`systemCapabilities`→`systemCaps` 等）的下游引用更新。

### 新增叶子 cap（`modules/<domain>/<name>/<facet>/{meta.nix,module.nix}`）

系统侧：`development/toolchain`、`development/assistant`、`core/cli-utils`、`operations/network-tools`、`operations/system-diagnostics`、`gaming/steam`、`gaming/performance`。
用户侧：`development/scripts`、`core/user-cli`，以及全爆炸应用叶子（见 Task 2 数据表）。

### 新增 view（`views/<domain>/<name>/{system,user}.nix`，纯数据）

`views/development/base/{system,user}.nix`、`views/gaming/base/{system,user}.nix`、`views/software/workstation/user.nix`。

### 共享身份

`systems/shared/users/rikki/default.nix`（home-manager `programs.git`）。

### 删除

`modules/identity/rikki`、`modules/development/base`、`modules/gaming/base`、`modules/software/workstation`、`modules/business/common`、`modules/lifetime/common`、`modules/software/base-cli`、`modules/software/{browser,communication,creative,desktop-tools,learning,network-access,remote-access,reverse-engineering}`。

### 测试与文档

新增 `tests/view-graph.sh`、`tests/identity-placement.sh`、`tests/module-leaf-audit.sh`；改 `tests/software-capabilities.sh`、`tests/migration-equivalence.sh`、`tests/framework-smoke.sh`；改 `README.md`、`AGENTS.md`。

---

## Chunk 1：新增叶子 cap 与 view（additive，不破坏现有构建）

本块只创建新文件，不改框架、不改宿主元数据、不删旧模块。现有 `nix eval` 仍应通过（旧配置完好；新 `views/` 未被读取，新叶子未被任何宿主选中）。

### Task 1：系统侧叶子 cap

**Files:**
- Create: `modules/development/toolchain/system/{meta.nix,module.nix}`
- Create: `modules/development/assistant/system/{meta.nix,module.nix}`
- Create: `modules/core/cli-utils/system/{meta.nix,module.nix}`
- Create: `modules/operations/network-tools/system/{meta.nix,module.nix}`
- Create: `modules/operations/system-diagnostics/system/{meta.nix,module.nix}`
- Create: `modules/gaming/steam/system/{meta.nix,module.nix}`
- Create: `modules/gaming/performance/system/{meta.nix,module.nix}`

- [ ] **Step 1: 写 `meta.nix`（统一模板，按表替换 optionPath/support）**

`meta.nix` 模板：

```nix
{
  optionPath = [ "kaguya" "<domain>" "<name>" ];
  support = {
    platform = [ "linux" "darwin" ];   # 见下表
    arch = [ "x86_64" "aarch64" ];
  };
  requires = [ ];
  conflicts = [ ];
}
```

各 cap 的 optionPath / platform：

| cap | optionPath | platform |
| --- | --- | --- |
| development/toolchain | `[ "kaguya" "development" "toolchain" ]` | `[ "linux" "darwin" ]` |
| development/assistant | `[ "kaguya" "development" "assistant" ]` | `[ "linux" "darwin" ]` |
| core/cli-utils | `[ "kaguya" "core" "cli-utils" ]` | `[ "linux" "darwin" ]` |
| operations/network-tools | `[ "kaguya" "operations" "network-tools" ]` | `[ "linux" "darwin" ]` |
| operations/system-diagnostics | `[ "kaguya" "operations" "system-diagnostics" ]` | `[ "linux" "darwin" ]` |
| gaming/steam | `[ "kaguya" "gaming" "steam" ]` | `[ "linux" ]` |
| gaming/performance | `[ "kaguya" "gaming" "performance" ]` | `[ "linux" ]` |

- [ ] **Step 2: 写各 `module.nix`**

`development/toolchain/system/module.nix`（迁自 `development/base/system`，需 `inputs`/`pkgs`）：

```nix
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.development.toolchain;
  alejandraPkg = inputs.alejandra.packages.${pkgs.system}.default or inputs.alejandra.defaultPackage.${pkgs.system};
  nilPkg = inputs.nil.packages.${pkgs.system}.default;
in {
  options.kaguya.development.toolchain.enable = lib.mkEnableOption "开发工具链能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gnumake
      nix-output-monitor
      nixfmt-rfc-style
      alejandraPkg
      nilPkg
    ];
    programs.direnv.enable = true;
  };
}
```

`development/assistant/system/module.nix`（迁自 `development/base/system`）：

```nix
{
  config,
  lib,
  unstable,
  ...
}: let
  cfg = config.kaguya.development.assistant;
in {
  options.kaguya.development.assistant = {
    enable = lib.mkEnableOption "开发助手能力";
    AIPackage = lib.mkOption {
      type = lib.types.package;
      default = unstable.AI-code;
      description = "AI 包来源。";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.AI-wrapper = {
      enable = true;
      package = cfg.AIPackage;
    };
  };
}
```

`core/cli-utils/system/module.nix`：

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.core.cli-utils;
in {
  options.kaguya.core.cli-utils.enable = lib.mkEnableOption "通用 CLI 工具能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      axel
      nano
      vim
      wget
      curl
      zip
      xz
      unzip
      p7zip
      ripgrep
      file
      which
      tree
      gnused
      gnutar
      gawk
      zstd
      cowsay
      mailutils
    ];
  };
}
```

`operations/network-tools/system/module.nix`：

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.operations.network-tools;
in {
  options.kaguya.operations.network-tools.enable = lib.mkEnableOption "网络排障工具能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mtr
      iperf3
      dnsutils
      aria2
      nmap
      ipcalc
      netcat-gnu
    ];
  };
}
```

`operations/system-diagnostics/system/module.nix`（btop/iftop/lsof 跨平台，其余 Linux）：

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.operations.system-diagnostics;
in {
  options.kaguya.operations.system-diagnostics.enable = lib.mkEnableOption "系统诊断工具能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        btop
        iftop
        lsof
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        iotop
        strace
        ltrace
        sysstat
        lm_sensors
        ethtool
        pciutils
        usbutils
        mission-center
      ];
  };
}
```

`gaming/steam/system/module.nix`（迁自 `gaming/base/system`）：

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.gaming.steam;
in {
  options.kaguya.gaming.steam.enable = lib.mkEnableOption "Steam 游戏平台能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.steam ];
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
```

`gaming/performance/system/module.nix`：

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.gaming.performance;
in {
  options.kaguya.gaming.performance.enable = lib.mkEnableOption "游戏性能工具能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mangohud
      gamemode
    ];
    programs.gamemode.enable = true;
  };
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/development/toolchain modules/development/assistant modules/core/cli-utils modules/operations modules/gaming/steam modules/gaming/performance
git commit -S -m "feat: 新增系统侧叶子 cap（toolchain/assistant/cli-utils/network-tools/system-diagnostics/steam/performance）"
```

### Task 2：用户侧叶子 cap（含全爆炸应用叶子）

**Files:**
- Create: `modules/development/scripts/user/{meta.nix,module.nix}`
- Create: `modules/core/user-cli/user/{meta.nix,module.nix}`
- Create: `modules/software/<app>/user/{meta.nix,module.nix}`（见数据表，逐个创建）

- [ ] **Step 1: 写 `development/scripts/user`（迁自 `development/base/user` 的脚本/shell 部分）**

先复制脚本目录：

```bash
mkdir -p modules/development/scripts/user
git mv modules/development/base/user/scripts modules/development/scripts/user/scripts
```

`modules/development/scripts/user/meta.nix`：

```nix
{
  optionPath = [ "kaguya" "development" "scripts" ];
  support = {
    platform = [ "linux" "darwin" ];
    arch = [ "x86_64" "aarch64" ];
  };
  requires = [ ];
  conflicts = [ ];
}
```

`modules/development/scripts/user/module.nix`：

```nix
{
  config,
  lib,
  ...
}: let
  cfg = config.kaguya.development.scripts;
  scriptsDir = ./scripts;
  scriptFiles = builtins.readDir scriptsDir;
  deployScripts = lib.mapAttrs' (
    name: _:
      lib.nameValuePair ".local/bin/${lib.removeSuffix ".sh" name}" {
        source = scriptsDir + "/${name}";
        executable = true;
      }
  ) (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".sh" name) scriptFiles);
in {
  options.kaguya.development.scripts.enable = lib.mkEnableOption "开发脚本与 shell 引导能力";

  config = lib.mkIf cfg.enable {
    home.file = deployScripts;
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.opencode/bin"
    ];
    programs.fish = {
      enable = true;
      shellAliases = {
        "0file" = "curl -F\"file=@$1\" https://envs.sh";
        "0pb" = "curl -F\"file=@-;\" https://envs.sh";
        "0url" = "curl -F\"url=$1\" https://envs.sh";
        "0short" = "curl -F\"shorten=$1\" https://envs.sh";
      };
      interactiveShellInit = ''
        set fish_greeting
      '';
    };
    programs.starship.enable = true;
  };
}
```

- [ ] **Step 2: 写 `core/user-cli/user`（迁自 `software/base-cli`）**

`meta.nix`：optionPath `[ "kaguya" "core" "user-cli" ]`，support `[ "linux" "darwin" ]` / `[ "x86_64" "aarch64" ]`，空 requires/conflicts。

`module.nix`：

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.core.user-cli;
in {
  options.kaguya.core.user-cli.enable = lib.mkEnableOption "用户基础 CLI 能力";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bc
      jq
      fastfetch
    ];
  };
}
```

- [ ] **Step 3: 应用叶子模板**

每个应用叶子 `modules/software/<name>/user/`：

`meta.nix`：

```nix
{
  optionPath = [ "kaguya" "software" "<name>" ];
  support = {
    platform = <PLATFORM>;     # 见数据表
    arch = [ "x86_64" "aarch64" ];
  };
  requires = [ ];
  conflicts = [ ];
}
```

> `<name>` 含连字符时（如 `tor-browser`/`signal-desktop`/`sing-box`/`gemini-cli`/`obs-studio`/`osu-lazer`），`optionPath` 末段用字符串字面量 `"tor-browser"` 等，并在 module 中用 `config.kaguya.software."tor-browser"` 引用。

`module.nix`（单包模板）：

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.<name>;
in {
  options.kaguya.software.<name>.enable = lib.mkEnableOption "<name> 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.<PKG> ];
  };
}
```

- [ ] **Step 4: 按数据表逐个生成应用叶子**

| name | PKG | platform |
| --- | --- | --- |
| firefox | `firefox` | `[ "linux" "darwin" ]` |
| tor-browser | `tor-browser` | `[ "linux" ]` |
| thunderbird | `thunderbird` | `[ "linux" "darwin" ]` |
| qq | `qq` | `[ "linux" ]` |
| feishu | `feishu` | `[ "linux" ]` |
| signal-desktop | `signal-desktop` | `[ "linux" ]` |
| gimp | `gimp` | `[ "linux" "darwin" ]` |
| typst | `typst` | `[ "linux" "darwin" ]` |
| kdenlive | `kdePackages.kdenlive` | `[ "linux" ]` |
| typora | `typora` | `[ "linux" ]` |
| gnome-software | `gnome-software` | `[ "linux" ]` |
| remmina | `remmina` | `[ "linux" ]` |
| filezilla | `filezilla` | `[ "linux" ]` |
| anki | `anki` | `[ "linux" ]` |
| calibre | `calibre` | `[ "linux" ]` |
| xray | `xray` | `[ "linux" "darwin" ]` |
| sing-box | `sing-box` | `[ "linux" "darwin" ]` |
| v2rayn | `v2rayn` | `[ "linux" ]` |
| gnucash | `gnucash` | `[ "linux" ]` |
| spotify | `spotify` | `[ "linux" "darwin" ]` |
| vscode | `vscode` | `[ "linux" "darwin" ]` |
| gemini-cli | `gemini-cli` | `[ "linux" "darwin" ]` |
| treefmt | `treefmt` | `[ "linux" "darwin" ]` |
| obs-studio | `obs-studio` | `[ "linux" "darwin" ]` |
| osu-lazer | `osu-lazer-bin` | `[ "linux" ]` |
| hmcl | `hmcl` | `[ "linux" ]` |
| mindustry | `mindustry` | `[ "linux" ]` |
| ddnet | `ddnet` | `[ "linux" ]` |
| vlc | `vlc` | `[ "linux" ]` |

特例 `ghidra`（带扩展，双包）：

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.ghidra;
in {
  options.kaguya.software.ghidra.enable = lib.mkEnableOption "Ghidra 逆向分析能力";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ghidra
      ghidra-extensions.ghidra-golanganalyzerextension
    ];
  };
}
```

`ghidra/user/meta.nix`：support platform `[ "linux" ]`。`software/logseq` 维持现状不动。

- [ ] **Step 5: Commit**

```bash
git add modules/development/scripts modules/core/user-cli modules/software
git commit -S -m "feat: 新增用户侧叶子 cap 与全爆炸应用叶子"
```

### Task 3：view facet 文件

**Files:**
- Create: `views/development/base/{system.nix,user.nix}`
- Create: `views/gaming/base/{system.nix,user.nix}`
- Create: `views/software/workstation/user.nix`

- [ ] **Step 1: 写 view 文件（纯数据）**

`views/development/base/system.nix`：

```nix
{
  support = {
    platform = [ "linux" "darwin" ];
    arch = [ "x86_64" "aarch64" ];
  };
  includes = [ ];
  caps = [
    "development/toolchain"
    "core/cli-utils"
    "operations/network-tools"
    "operations/system-diagnostics"
  ];
}
```

`views/development/base/user.nix`：

```nix
{
  support = {
    platform = [ "linux" "darwin" ];
    arch = [ "x86_64" "aarch64" ];
  };
  includes = [ ];
  caps = [
    "development/scripts"
    "software/vscode"
    "software/gemini-cli"
    "software/treefmt"
  ];
}
```

`views/gaming/base/system.nix`（support 仅 linux）：

```nix
{
  support = {
    platform = [ "linux" ];
    arch = [ "x86_64" "aarch64" ];
  };
  includes = [ ];
  caps = [
    "gaming/steam"
    "gaming/performance"
  ];
}
```

`views/gaming/base/user.nix`（support 仅 linux）：

```nix
{
  support = {
    platform = [ "linux" ];
    arch = [ "x86_64" "aarch64" ];
  };
  includes = [ ];
  caps = [
    "software/obs-studio"
    "software/osu-lazer"
    "software/hmcl"
    "software/mindustry"
    "software/ddnet"
  ];
}
```

`views/software/workstation/user.nix`（仅跨平台叶子）：

```nix
{
  support = {
    platform = [ "linux" "darwin" ];
    arch = [ "x86_64" "aarch64" ];
  };
  includes = [ ];
  caps = [
    "software/thunderbird"
    "software/gimp"
    "software/typst"
  ];
}
```

- [ ] **Step 2: Commit**

```bash
git add views
git commit -S -m "feat: 新增 development/gaming/workstation 聚合视图"
```

### Task 4：共享身份文件

**Files:**
- Create: `systems/shared/users/rikki/default.nix`

- [ ] **Step 1: 写共享 git 身份（home-manager）**

`systems/shared/users/rikki/default.nix`：

```nix
{...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "Rikki";
        email = "rikki@member.fsf.org";
        signingkey = "3927D7F5365B0203";
      };
      commit.gpgsign = true;
    };
  };
}
```

- [ ] **Step 2: 验证现有构建未被破坏（新文件均未被引用）**

Run: `nix --extra-experimental-features 'nix-command flakes' eval path:./#darwinConfigurations.laptop-mbpM2.config.system.stateVersion`
Expected: 正常输出（如 `6`），证明 additive 改动未破坏现有 eval。

- [ ] **Step 3: Commit**

```bash
git add systems/shared
git commit -S -m "feat: 新增共享用户 rikki 的 git 身份默认值"
```

---

## Chunk 2：框架支持 view + `capability→cap` 改名（TDD）

### Task 5：先写失败的 view 解析测试

**Files:**
- Create: `tests/view-graph.sh`

- [ ] **Step 1: 写测试脚本**

参考既有 `tests/framework-smoke.sh` 的风格，用 `nix eval --expr` 调 `flake.lib.kaguya.buildPlanFromMeta` 或直接 import `lib/capGraph.nix`。`tests/view-graph.sh`：

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
NIX="nix --extra-experimental-features 'nix-command flakes'"

# 临时 fixtures
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 正常展开：view 含 includes + caps
mkdir -p "$TMP/views/a/base"
cat > "$TMP/views/a/base/system.nix" <<'EOF'
{ support = { platform = [ "linux" ]; arch = [ "x86_64" ]; }; includes = [ ]; caps = [ "x/leaf" ]; }
EOF

assert_contains() { echo "$1" | grep -q "$2" || { echo "FAIL: 期望包含 $2，实际: $1"; exit 1; }; }

# 1. 正常展开
OUT=$(eval "$NIX" eval --impure --expr "
  let g = import ./lib/capGraph.nix { lib = (import <nixpkgs> {}).lib; };
  in (g.resolveViews { locale = \"zh-CN\"; viewsDir = $TMP/views; target = { platform = \"linux\"; arch = \"x86_64\"; }; facet = \"system\"; requested = [ \"a/base\" ]; }).caps
" --json)
assert_contains "$OUT" "x/leaf"

# 2. 未知 view 报错
if eval "$NIX" eval --impure --expr "
  let g = import ./lib/capGraph.nix { lib = (import <nixpkgs> {}).lib; };
  in g.resolveViews { locale = \"zh-CN\"; viewsDir = $TMP/views; target = { platform = \"linux\"; arch = \"x86_64\"; }; facet = \"system\"; requested = [ \"a/missing\" ]; }
" 2>/dev/null; then
  echo "FAIL: 未知 view 应报错"; exit 1
fi

echo "PASS: view-graph"
```

- [ ] **Step 2: 运行确认失败**

Run: `./tests/view-graph.sh`
Expected: FAIL（`lib/capGraph.nix` 尚不存在 / `resolveViews` 未定义）

### Task 6：`errors.nix` 改名 + 新增 `view.*`

**Files:**
- Modify: `lib/errors.nix`

- [ ] **Step 1: 把 `capability.*` 键改为 `cap.*`（zh-CN 与 en-US 两个 bundle 同步）**

将 8 个键 `capability.invalidId`/`unknown`/`missingFacet`/`invalidMetaField`/`unsupportedPlatform`/`unsupportedArch`/`conflict`/`cycle` 重命名为 `cap.*`，文案中的“capability”可保留中文“能力”。

- [ ] **Step 2: 在两个 bundle 新增 `view.*`**

zh-CN：

```nix
"view.invalidId" = err: "view 标识 `${err.subject}` 不合法，必须是 `<domain>/<name>` 形式。";
"view.unknown" = err: "未知 view: ${err.subject}";
"view.missingFacet" = err: "view `${err.subject}` 缺少 `${err.facet}` facet。";
"view.unsupportedPlatform" = err: "view `${err.subject}.${err.facet}` 不支持当前平台 `${err.actual}`，支持的平台为 ${lib.concatStringsSep ", " err.expected}。";
"view.unsupportedArch" = err: "view `${err.subject}.${err.facet}` 不支持当前架构 `${err.actual}`，支持的架构为 ${lib.concatStringsSep ", " err.expected}。";
"view.cycle" = err: "检测到 view 依赖循环: ${lib.concatStringsSep " -> " err.cycle}";
"view.invalidField" = err: "view `${err.subject}` 的字段 `${err.field}` 非法。";
```

en-US：对应英文文案（与现有 `capability.*` 英文风格一致）。

- [ ] **Step 3: Commit**

```bash
git add lib/errors.nix
git commit -S -m "refactor: errors 改 capability.* 为 cap.* 并新增 view.*"
```

### Task 7：`capabilityGraph.nix` → `capGraph.nix`（改名 + view 解析 + 合流）

**Files:**
- Rename: `lib/capabilityGraph.nix` → `lib/capGraph.nix`
- Modify: `lib/capGraph.nix`

- [ ] **Step 1: git mv 文件**

```bash
git mv lib/capabilityGraph.nix lib/capGraph.nix
```

- [ ] **Step 2: 内部改名（用 LSP/编辑）**

- `resolveCapabilities` → `resolveCaps`
- `loadFacetMeta` → `loadCapFacet`
- `parseCapabilityId` → `parseCapId`
- `capabilityDir` → `capDir`
- `resolveCaps` 返回字段 `capabilities` → `caps`（即 `capabilities = resolvedIds;` 改为 `caps = resolvedIds;`），其余 `facets`/`modulePaths`/`optionDefaults` 不变。
- 错误码字符串 `capability.*` → `cap.*`（与 Task 6 对齐）。

- [ ] **Step 3: 新增 view 解析函数（在 `resolveCapabilities` 之后插入）**

```nix
parseViewId = locale: viewId: let
  match = builtins.match "([^/]+)/([^/]+)" viewId;
in
  if match == null
  then errors.throwError locale { code = "view.invalidId"; subject = viewId; }
  else {
    domain = builtins.elemAt match 0;
    name = builtins.elemAt match 1;
  };

viewDir = locale: viewsDir: viewId: let
  parts = parseViewId locale viewId;
in
  viewsDir + "/${parts.domain}/${parts.name}";

loadViewFacet = {
  locale,
  viewsDir,
  viewId,
  facet,
  target,
}: let
  baseDir = viewDir locale viewsDir viewId;
  facetPath = baseDir + "/${facet}.nix";
in
  if !builtins.pathExists baseDir
  then errors.throwError locale { code = "view.unknown"; subject = viewId; }
  else if !builtins.pathExists facetPath
  then errors.throwError locale { code = "view.missingFacet"; subject = viewId; inherit facet; }
  else let
    raw = import facetPath;
    data = ensureAttrs locale "view" "view" raw;
    support = ensureAttrs locale "view" "support" (data.support or {});
    platform = ensureListOfStrings locale "view" "support.platform" (support.platform or []);
    arch = ensureListOfStrings locale "view" "support.arch" (support.arch or []);
    includes = ensureListOfStrings locale "view" "includes" (data.includes or []);
    caps = ensureListOfStrings locale "view" "caps" (data.caps or []);
    _platformCheck =
      if builtins.elem target.platform platform
      then true
      else errors.throwError locale { code = "view.unsupportedPlatform"; subject = viewId; inherit facet; expected = platform; actual = target.platform; };
    _archCheck =
      if builtins.elem target.arch arch
      then true
      else errors.throwError locale { code = "view.unsupportedArch"; subject = viewId; inherit facet; expected = arch; actual = target.arch; };
  in {
    inherit viewId facet includes caps;
  };

resolveViews = {
  locale,
  viewsDir,
  target,
  facet,
  requested,
}: let
  visit = state: viewId:
    if state.seen.${viewId} or false
    then state
    else if builtins.elem viewId state.stack
    then errors.throwError locale { code = "view.cycle"; cycle = state.stack ++ [viewId]; }
    else let
      nextState = state // { stack = state.stack ++ [viewId]; };
      view = loadViewFacet { inherit locale viewsDir viewId facet target; };
      afterIncludes = lib.foldl' visit nextState view.includes;
    in
      afterIncludes
      // {
        stack = state.stack;
        seen = afterIncludes.seen // { ${viewId} = true; };
        caps = afterIncludes.caps ++ view.caps;
        views = afterIncludes.views ++ [viewId];
      };
  finalState = lib.foldl' visit { seen = {}; stack = []; caps = []; views = []; } requested;
in {
  views = finalState.views;
  caps = lib.unique finalState.caps;
};
```

- [ ] **Step 4: `buildPlanFromMeta` 接入 view（系统侧）**

在解析 `hostCapabilities` 处改为：

```nix
hostViews = ensureListOfStrings locale hostName "views" (rawMeta.views or []);
hostCaps = ensureListOfStrings locale hostName "caps" (rawMeta.caps or []);
```

并新增参数 `viewsDir`（与 `modulesDir`/`hardwareDir` 并列）。系统解析改为：

```nix
systemViewResolution = resolveViews {
  inherit locale viewsDir target;
  facet = "system";
  requested = hostViews;
};
systemResolution = resolveCaps {
  inherit locale modulesDir target;
  facet = "system";
  requested = lib.unique (systemViewResolution.caps ++ hostCaps);
};
```

- [ ] **Step 5: `normalizeUser` 与用户解析接入 view**

`normalizeUser` 增加 `views = ensureListOfStrings ... (attrs.views or []);` 与 `caps = ensureListOfStrings ... (attrs.caps or []);`（替换原 `capabilities`）。`resolvedUsers` 解析改为：

```nix
userViewResolution = resolveViews {
  inherit locale viewsDir target;
  facet = "user";
  requested = if userCfg.enable then userCfg.views else [];
};
userResolution = resolveCaps {
  inherit locale modulesDir target;
  facet = "user";
  requested = if userCfg.enable then lib.unique (userViewResolution.caps ++ userCfg.caps) else [];
};
```

并在用户结果合并写入 `caps = userResolution.caps;`、`views = userViewResolution.views;`、`modulePaths`、`optionDefaults`。

- [ ] **Step 6: `buildPlan` 输出字段改名 + 新增 views**

`systemCapabilities`→`systemCaps`、`systemModulePaths`→`systemCapModulePaths`、新增 `systemViews = systemViewResolution.views;`、`systemOptionDefaults` 不变；`resolvedUsers.*` 已含 `caps`/`views`。

- [ ] **Step 7: 运行 view 测试**

Run: `./tests/view-graph.sh`
Expected: PASS

### Task 8：`parts/systems.nix` 与 flake 输出更新

**Files:**
- Modify: `parts/systems.nix`

- [ ] **Step 1: 改 graph 引用与 mkPlan**

```nix
graph = extendedLib.capGraph;
```

`mkPlan` 增加 `viewsDir = ../views;`。

- [ ] **Step 2: 更新 buildPlan 字段下游引用**

`mkFrameworkModule` 中 `plan.systemOptionDefaults` 不变；凡引用 `plan.systemModulePaths` 改为 `plan.systemCapModulePaths`；`plan.systemCapabilities`（若有）改 `plan.systemCaps`。`systemBuildArgs.modules` 中 `++ plan.systemModulePaths` → `++ plan.systemCapModulePaths`。

- [ ] **Step 3: `flake.lib.kaguya` 改名跟随**

`inherit (graph) buildPlanFromMeta mergeAttrsets;` 保持；确保 `graph` 已指向 `capGraph`。

- [ ] **Step 4: Commit**

```bash
git add lib/capGraph.nix parts/systems.nix tests/view-graph.sh
git commit -S -m "feat: capGraph 支持 view 解析并统一 capability→cap 命名"
```

---

## Chunk 3：宿主/用户迁移 + 服务净化 + 删除旧模块（原子切换）

### Task 9：迁移宿主与用户 `meta.nix` 到 `views + caps`

**Files:**
- Modify: `systems/laptop-asus-tx4-personal/meta.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`

- [ ] **Step 1: asus 宿主 `meta.nix`**

```nix
{
  target = { platform = "linux"; arch = "x86_64"; };
  hardware = "asus-tianxuan4";
  locale = "zh-CN";

  views = [ "development/base" "gaming/base" ];
  caps = [
    "desktop/gnome"
    "services/docker"
    "services/flatpak"
    "services/vm"
    "services/tailscale"
    "services/cups"
    "core/fonts"
    "core/input"
    "development/emacs"
  ];

  users.rikki = import ./users/rikki/meta.nix;

  overrides = {
    kaguya.services.docker.storageDriver = "btrfs";
    # Flatpak 应用清单（迁自模块默认值，见 Task 10）
    kaguya.services.flatpak.packages = [ /* Task 10 填入 */ ];
  };
}
```

- [ ] **Step 2: asus 用户 `meta.nix`（去掉 git override，改 views+caps）**

```nix
{
  enable = true;
  admin = true;
  shell = "fish";
  views = [ "development/base" "software/workstation" "gaming/base" ];
  caps = [
    "core/user-cli"
    "software/firefox"
    "software/qq"
    "software/feishu"
    "software/signal-desktop"
    "software/kdenlive"
    "software/typora"
    "software/gnome-software"
    "software/remmina"
    "software/filezilla"
    "software/xray"
    "software/sing-box"
    "software/v2rayn"
    "software/anki"
    "software/calibre"
    "software/ghidra"
    "software/logseq"
    "software/gnucash"
    "software/spotify"
  ];
}
```

（删除原 `overrides.kaguya.programs.git.email`——身份已迁共享文件。）

- [ ] **Step 3: mbp 宿主 `meta.nix`**

```nix
{
  target = { platform = "darwin"; arch = "aarch64"; };
  hardware = "mbpM2";
  locale = "zh-CN";

  views = [ "development/base" ];
  caps = [ "development/emacs" "cross-platform/linux-builder" ];

  users.rikki = import ./users/rikki/meta.nix;
}
```

- [ ] **Step 4: mbp 用户 `meta.nix`（删除两条旧 override）**

```nix
{
  enable = true;
  admin = true;
  shell = "fish";
  views = [ "development/base" "software/workstation" ];
  caps = [
    "core/user-cli"
    "software/xray"
    "software/sing-box"
    "software/spotify"
  ];
}
```

（删除原 `overrides.kaguya.development.base.vscode.enable` 与 `kaguya.software.browser.enable`——改由“不选 `software/vscode`/`software/firefox`”表达。）

- [ ] **Step 5: 宿主用户 `default.nix` 导入共享身份**

`systems/laptop-asus-tx4-personal/users/rikki/default.nix` 与 `systems/laptop-mbpM2/users/rikki/default.nix` 各 `imports = [ ../../../shared/users/rikki/default.nix ];`（按实际相对深度校正路径）。若已有内容，并入 `imports`。

### Task 10：Flatpak 服务净化

**Files:**
- Modify: `modules/services/flatpak/system/module.nix`
- Modify: `systems/laptop-asus-tx4-personal/meta.nix`

- [ ] **Step 1: 模块 `packages` 默认改为 `[]`**

把 `modules/services/flatpak/system/module.nix` 中 `packages` 选项的 28 项 `default` 改为 `default = [];`，保留 `remotes`（flathub 镜像）默认与 `enable`。

- [ ] **Step 2: 把 28 项清单迁入 asus 宿主 overrides**

将原默认列表整体粘贴到 Task 9 Step 1 的 `kaguya.services.flatpak.packages`：

```nix
kaguya.services.flatpak.packages = [
  "ar.xjuan.Cambalache" "com.google.Chrome" "com.obsproject.Studio" "com.valvesoftware.Steam"
  "com.tencent.WeChat" "dev.geopjr.Calligraphy" "org.gnome.Boxes" "org.gnome.Builder"
  "org.gnome.GHex" "org.inkscape.Inkscape" "org.kicad.KiCad" "org.libreoffice.LibreOffice"
  "org.octave.Octave" "org.qbittorrent.qBittorrent" "org.sdrangel.SDRangel" "org.telegram.desktop"
  "org.telegram.desktop.webview" "re.sonny.Workbench" "org.gnome.Fractal" "org.gnome.World.Secrets"
  "org.blender.Blender" "com.tencent.wemeet" "com.baidu.NetDisk" "io.github.Foldex.AdwSteamGtk"
  "org.gabmus.gfeeds" "com.belmoussaoui.Authenticator" "com.github.tchx84.Flatseal" "com.qq.QQ"
];
```

### Task 11：删除旧模块

**Files:**
- Delete: `modules/identity/`, `modules/business/`, `modules/lifetime/`
- Delete: `modules/development/base/`, `modules/gaming/base/`, `modules/software/workstation/`
- Delete: `modules/software/{base-cli,browser,communication,creative,desktop-tools,learning,network-access,remote-access,reverse-engineering}/`

- [ ] **Step 1: 删除并提交前先确认无引用**

Run: `./tests/module-leaf-audit.sh`（见 Task 13；此处先手动 grep 关键 id）。用 `lsp references` / `search` 确认 `kaguya.programs.git`、`kaguya.development.base`、`kaguya.software.browser` 等旧选项无残留引用。

- [ ] **Step 2: git rm**

```bash
git rm -r modules/identity modules/business modules/lifetime \
  modules/development/base modules/gaming/base modules/software/workstation \
  modules/software/base-cli modules/software/browser modules/software/communication \
  modules/software/creative modules/software/desktop-tools modules/software/learning \
  modules/software/network-access modules/software/remote-access modules/software/reverse-engineering
```

### Task 12：构建验证（原子切换收口）

- [ ] **Step 1: 两台主机 eval**

Run: `nix --extra-experimental-features 'nix-command flakes' eval path:./#darwinConfigurations.laptop-mbpM2.config.system.build.toplevel.drvPath`
Expected: 正常输出 drvPath（无 `cap.unknown` / `view.*` / 选项不存在错误）。

Run: `nix --extra-experimental-features 'nix-command flakes' eval path:./#nixosConfigurations.laptop-asus-tx4-personal.config.system.build.toplevel.drvPath`
Expected: 正常输出 drvPath。

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -S -m "refactor: 宿主/用户迁移到 views+caps，净化 flatpak，删除旧聚合与人名模块"
```

---

## Chunk 4：测试与文档

### Task 13：新增与更新测试

**Files:**
- Create: `tests/identity-placement.sh`, `tests/module-leaf-audit.sh`
- Modify: `tests/software-capabilities.sh`, `tests/migration-equivalence.sh`, `tests/framework-smoke.sh`

- [ ] **Step 1: `tests/module-leaf-audit.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
for bad in modules/identity modules/business modules/lifetime \
  modules/development/base modules/gaming/base modules/software/workstation \
  modules/software/base-cli modules/software/browser modules/software/communication; do
  if [ -e "$bad" ]; then echo "FAIL: 残留 $bad"; fail=1; fi
done
# modules/ 下不应出现 common/base 目录
if find modules -type d \( -name common -o -name base \) | grep -q .; then
  echo "FAIL: modules/ 下仍有 common/base"; fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: module-leaf-audit"
exit "$fail"
```

> 注：此处 `find`/`grep` 属测试脚本内的判定逻辑（计算事实），非交互式探索。

- [ ] **Step 2: `tests/identity-placement.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f systems/shared/users/rikki/default.nix ] || { echo "FAIL: 缺共享身份文件"; exit 1; }
[ ! -d modules/identity ] || { echo "FAIL: modules/identity 仍存在"; exit 1; }
echo "PASS: identity-placement"
```

- [ ] **Step 3: 更新 `software-capabilities.sh`**

把 Darwin 断言改为：`laptop-mbpM2` 的 home.packages 不含 `firefox`、不含 `vscode`；含 `spotify`、`thunderbird`。Linux：含 `firefox`、`gnucash`。具体用 `nix eval` 取 `home-manager` 配置的包名列表后 grep。

- [ ] **Step 4: 更新 `migration-equivalence.sh` 与 `framework-smoke.sh`**

`migration-equivalence.sh`：断言两台 `meta.nix` 含 `views` 键；`buildPlan` 含 `systemViews`/`systemCaps`。`framework-smoke.sh`：把 `buildPlan.systemCapabilities` 断言改 `systemCaps`，新增对 `systemViews` 的断言。

- [ ] **Step 5: 跑新增/更新测试**

Run: `./tests/view-graph.sh && ./tests/identity-placement.sh && ./tests/module-leaf-audit.sh && ./tests/software-capabilities.sh && ./tests/migration-equivalence.sh && ./tests/framework-smoke.sh`
Expected: 全 PASS

### Task 14：全量回归

- [ ] **Step 1: 跑全部测试**

Run: `for t in tests/*.sh; do echo "== $t"; bash "$t" || exit 1; done`
Expected: 全 PASS（含 host-user-layout / makefile-smoke / deploy-smoke / darwin-etc-compat / cleanup-check）

### Task 15：文档

**Files:**
- Modify: `README.md`, `AGENTS.md`
- Modify: 旧 spec/plan 标记 superseded

- [ ] **Step 1: 更新架构说明**

README/AGENTS：新增 `views/` 目录说明；`Capability Layout`→`Cap Layout`、`Capability Graph`→`Cap Graph`；宿主/用户 `meta.nix` 示例改为显式 `views = [ ... ]` + `caps = [ ... ]`；删除 `README.md` 中 `kaguya.programs.git.email` override 示例，改为说明身份在 `systems/shared/users/<name>/default.nix`。中文行文保留“能力/视图”。

- [ ] **Step 2: 标记取代的旧文档**

在以下文件头部加 `> SUPERSEDED by docs/superpowers/specs/2026-06-11-cap-view-architecture-design.md`：`2026-04-08-software-capability-refactor*`、`2026-04-08-capability-architecture-realignment.md`、`2026-04-08-development-base-split.md`、`2026-04-09-leaf-modules-and-views-*`。

- [ ] **Step 3: format + commit**

```bash
make format
git add -A
git commit -S -m "docs: 更新架构文档至 cap/view 模型并标记旧设计 superseded"
```

---

## Self-Review

**Spec coverage（逐条对照 spec）：**
- cap/view 双概念 + 目录 → Task 1-3、Task 7。
- 身份迁 systems/shared + 删 kaguya.programs.git schema + 处理 asus override/README → Task 4、Task 9 Step 2、Task 11、Task 15。
- capability→cap 全量改名（lib/函数/错误码/buildPlan/meta 字段） → Task 6-8。
- view 解析 + 平台规则（view 含 support，仅聚合跨平台叶子） → Task 7 Step 3、Task 3（workstation 仅 thunderbird/gimp/typst）。
- 全爆炸应用叶子 + 平台分类 → Task 2 数据表。
- flatpak 净化 → Task 10。
- 两台主机目标形态 → Task 9。
- mbp 不装 firefox/vscode 由“不选叶子”表达 → Task 9 Step 4。
- 测试（view-graph/identity-placement/module-leaf-audit + 更新） → Task 13-14。

**Placeholder 扫描：** Task 9 Step 1 中 `kaguya.services.flatpak.packages = [ /* Task 10 填入 */ ]` 是显式前向引用，实际清单在 Task 10 Step 2 给全；其余步骤均含完整代码/命令。无 TBD/“适当处理”类占位。

**类型/命名一致性：** `resolveCaps`/`resolveViews`/`loadCapFacet`/`loadViewFacet`/`parseCapId`/`parseViewId`/`capDir`/`viewDir` 在 Task 7 定义并在 Task 8 引用一致；buildPlan 字段 `systemCaps`/`systemCapModulePaths`/`systemViews` 在 Task 7 Step 6 定义、Task 8 Step 2 消费、Task 13 Step 4 断言一致；meta 字段 `views`/`caps` 在 Task 7-9、Task 13 一致。

**已知实现期校验点：** `spotify`/`gnucash` 等 darwin 可用性以 nixpkgs 实际为准（Task 12 eval 会暴露）；`v2rayn`/`feishu`/`qq` 等包名以当前 nixpkgs 属性名为准。
