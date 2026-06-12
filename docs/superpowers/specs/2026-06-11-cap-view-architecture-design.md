# Cap 与 View 架构设计

## 背景与谱系

KaguyaNix 的 `modules/` 经历了四次迭代设计，目标始终是“消除大包、人名模块与弱语义分类”，但机制与落点逐次演进：

1. **`2026-04-08-software-capability-refactor`（最早）**：起点是 `users/rikki/profiles/software.nix` → `software/common` 大包 → 拆为 `software/workstation` 聚合 + 一批软件叶子（base-cli/browser/communication/creative/desktop-tools/remote-access/…）。聚合靠 `requires`。**这是当前已实现的状态。**
2. **`2026-04-08-capability-architecture-realignment`**：扩展到整个 `modules/`，提出“叶子 / 聚合 / 身份预设”三角色模型，净化 `identity/rikki`（仍留 `modules/`），收缩 `services/flatpak`，删除 `business/common`、`lifetime/common`、`software/base-cli`。机制不变。
3. **`2026-04-08-development-base-split`**：realignment 的窄切片，专注拆分 `development/base/system` 与浏览器解绑。
4. **`2026-04-09-leaf-modules-and-views`（最新）**：引入 `views/` 一等结构，`modules/` 只剩叶子，`identity` 搬出模块层，软件炸为单应用叶子。其迁移计划已显式将 04-08 的文档标记为 superseded。

**本设计统一并取代上述四次迭代**：采纳 #4 的“叶子 / 聚合双结构”作为目标架构，叠加一层此前四份都未触及的**命名现代化**——把英文代码标识 `capability` 缩短为 `cap`，聚合概念定名 `view`。

## 设计目标

1. `modules/` 只承载叶子能力（`cap`）。
2. 聚合关系由独立的 `views/` 结构表达（`view`），纯数据、不含实现。
3. 用户身份与个人默认值移出模块层，回到 `systems/`。
4. 用户态软件叶子优先使用具体应用名（忠实 #4 的全爆炸粒度）。
5. 把英文代码标识 `capability` 统一缩短为 `cap`，降低书写与阅读负担；中文行文仍用“能力 / 视图”。
6. 宿主机与用户实例显式区分“叶子能力选择（`caps`）”与“聚合视图选择（`views`）”。

## 非目标

1. 不改动“两阶段构建”根本模型（预构建纯数据校验 + 真实构建）。
2. 不引入 `profile` 或 per-system 旧机制。
3. 不保留任何 `capability` 旧标识的兼容别名；一次性干净切换。
4. 不改 `kaguya.<domain>.<name>` 选项命名空间——`optionPath` 与本次改名无关。

## 核心概念

### `cap`（叶子能力）

- 单一职责，直接拥有实现：`environment.systemPackages` / `home.packages` / `programs.*` / `services.*`。
- 在不知道调用方是谁时自洽。
- 落点：`modules/<domain>/<name>/<facet>/{meta.nix,module.nix}`，`facet ∈ {system,user}`。

### `view`（聚合视图）

- 纯数据，只组合不实现。
- 无 `module.nix`、无 `optionPath`。
- 落点：`views/<domain>/<name>/{system.nix,user.nix}`。
- 单个 facet 文件返回：

  ```nix
  {
    support = {
      platform = [ "linux" "darwin" ];
      arch = [ "x86_64" "aarch64" ];
    };
    includes = [ ];          # 其他 view
    caps = [ ];              # 叶子 cap
  }
  ```

### 身份（不再是 cap）

- 删除 `modules/identity/`。
- Git 身份默认值迁到 `systems/shared/users/<name>/default.nix`（home-manager `programs.git`）。
- 各宿主机用户 `systems/<host>/users/<name>/default.nix` 导入共享文件。
- 身份成为“用户实例层复用”，而非“能力层复用”。
- 当前 `identity/rikki` 定义的 `kaguya.programs.git` 选项 schema 一并删除，改为共享文件直写 home-manager `programs.git`（保留 `rikki@member.fsf.org`、signingKey `3927D7F5365B0203`、`signCommits`、`lfs`）。
- 已知消费者须同步处理：`systems/laptop-asus-tx4-personal/users/rikki/meta.nix` 的 `overrides.kaguya.programs.git.email`（与默认值相同、冗余，删除）；`README.md` 中以该选项为例的 override 说明改写为新方式。

## 目录布局

```text
modules/<domain>/<name>/<facet>/{meta.nix,module.nix}   # 全是 cap
views/<domain>/<name>/{system.nix,user.nix}             # 全是 view
systems/shared/users/<name>/default.nix                 # 共享身份 / 个人默认
systems/<host>/users/<name>/default.nix                 # 导入共享文件 + 宿主局部
```

## 数据模型

### 宿主机 `systems/<host>/meta.nix`

```nix
{
  target = { platform = "..."; arch = "..."; };
  hardware = "...";
  locale = "zh-CN";
  views = [ ];        # 聚合视图选择
  caps = [ ];         # 叶子能力选择
  users.<name> = import ./users/<name>/meta.nix;
  overrides = { };
}
```

### 用户 `systems/<host>/users/<name>/meta.nix`

```nix
{
  enable = true;
  admin = true;
  shell = "fish";
  extraGroups = [ ];
  views = [ ];        # 聚合视图选择
  caps = [ ];         # 叶子能力选择
  overrides = { };
  stateVersion = "24.05";
  homeDirectory = null;   # 缺省按平台推导
}
```

### cap `meta.nix`（结构不变，概念改称 cap）

```nix
{
  optionPath = [ "kaguya" "<domain>" "<name>" ];
  support = { platform = [ ]; arch = [ ]; };
  requires = [ ];
  conflicts = [ ];
}
```

### view facet 文件

见“核心概念 / view”中的 schema：`support` / `includes` / `caps`。

## 命名迁移（`capability` → `cap`，一次性）

| 类别 | 旧 | 新 |
| --- | --- | --- |
| lib 文件 | `lib/capabilityGraph.nix` | `lib/capGraph.nix` |
| lib 导出名 | `capabilityGraph` | `capGraph` |
| 函数 | `resolveCapabilities` | `resolveCaps` |
| 函数 | `loadFacetMeta` | `loadCapFacet` |
| 函数 | `parseCapabilityId` | `parseCapId` |
| 函数 | `capabilityDir` | `capDir` |
| meta 字段 | `capabilities`（宿主/用户） | `caps` |
| buildPlan | `systemCapabilities` | `systemCaps` |
| buildPlan | `systemModulePaths` | `systemCapModulePaths` |
| buildPlan | `resolvedUsers.*.capabilities` | `resolvedUsers.*.caps` |
| 错误码前缀 | `capability.*` | `cap.*` |

- `buildPlan` 保留 `systemOptionDefaults`、`hostOverrides`、`hardware`、`target`、`locale`、`users`；新增 `systemViews`、`resolvedUsers.*.views`。
- `node.*`、`hardware.*` 错误码不变。
- `parts/systems.nix`：`graph = extendedLib.capGraph`；`flake.lib.kaguya` 的 `inherit (graph) …` 跟随改名。
- 文档（README / AGENTS）：英文代码上下文 `capability` → `cap`；新增 `views/` 说明；章节名 `Capability Layout` → `Cap Layout`、`Capability Graph` → `Cap Graph`。中文行文保留“能力 / 视图”。

## 框架改动

### `lib/capGraph.nix`

新增 view 解析（与现有 cap 解析对称）：

- `parseViewId`、`viewDir`、`loadViewFacet`、`resolveViews`。
- `resolveViews` 要求：校验 `support.platform` / `support.arch`；展开 `includes`；视图循环检测；汇总叶子 `caps`。

`buildPlanFromMeta` 新流程：

1. 解析宿主/用户 `views`（`resolveViews`）。
2. 得到展开后的叶子 caps。
3. 与显式 `caps` 合并去重。
4. 进入现有 `resolveCaps`（保留环检测、冲突检测、支持表校验）。
5. 结果写入 `buildPlan`：`systemViews` / `systemCaps` / `systemCapModulePaths` / `systemOptionDefaults` 及 `resolvedUsers.*.{views,caps,modulePaths,optionDefaults}`。

### `lib/errors.nix`

- `capability.*` → `cap.*`（zh-CN / en-US 双语同步）。
- 新增 `view.*`：`invalidId` / `unknown` / `missingFacet` / `unsupportedPlatform` / `unsupportedArch` / `cycle` / `invalidField`，双语补齐。

### `parts/systems.nix`

- `mkPlan` 传入 `viewsDir = ../views`。
- `graph` 改名引用 `extendedLib.capGraph`。
- 框架模块组装逻辑不变（`systemCapModulePaths` 仍并入 `modules`）。

## 模块迁移清单

### 新建 view

- `views/development/base/{system.nix,user.nix}`
- `views/gaming/base/{system.nix,user.nix}`
- `views/software/workstation/user.nix`

### view 内容与平台规则

view 自带 `support` 表，且只能聚合“其 support 覆盖的每个平台都支持的叶子”——否则 `resolveCaps` 会在该平台抛 `cap.unsupportedPlatform`。平台特定应用因此要么进平台受限的 view，要么进用户显式 `caps`。

- `views/development/base/system.nix` — support `[linux darwin]`，caps：`development/toolchain` `development/assistant` `core/cli-utils` `operations/network-tools` `operations/system-diagnostics`
- `views/development/base/user.nix` — support `[linux darwin]`，caps：`development/scripts` `software/vscode` `software/gemini-cli` `software/treefmt`
- `views/software/workstation/user.nix` — support `[linux darwin]`，caps：仅跨平台桌面应用 `software/thunderbird` `software/gimp` `software/typst`（不含浏览器；Linux 专属桌面应用由用户显式选）
- `views/gaming/base/system.nix` — support `[linux]`，caps：`gaming/steam` `gaming/performance`
- `views/gaming/base/user.nix` — support `[linux]`，caps：`software/obs-studio` `software/osu-lazer` `software/hmcl` `software/mindustry` `software/ddnet`

### 新建系统侧 cap

- `development/toolchain/system`：`git` `gnumake` `alejandra` `nil` `nixfmt-rfc-style` `nix-output-monitor` + `programs.direnv.enable`
- `development/assistant/system`：`programs.AI-wrapper`（含 `AIPackage` 选项）
- `core/cli-utils/system`：`axel` `nano` `vim` `wget` `curl` `zip` `xz` `unzip` `p7zip` `ripgrep` `file` `which` `tree` `gnused` `gnutar` `gawk` `zstd` `cowsay` `mailutils`
- `operations/network-tools/system`：`mtr` `iperf3` `dnsutils` `aria2` `nmap` `ipcalc` `netcat-gnu`
- `operations/system-diagnostics/system`：`btop` `iftop` `lsof` + Linux `iotop` `strace` `ltrace` `sysstat` `lm_sensors` `ethtool` `pciutils` `usbutils` `mission-center`
- `gaming/steam/system`：`steam`
- `gaming/performance/system`：`mangohud` `gamemode`

### 新建用户侧 cap

- `development/scripts/user`：`home.file` 部署脚本 + `home.sessionPath` + `programs.fish` 别名/greeting + `programs.starship`
- `core/user-cli/user`：`bc` `jq` `fastfetch`（忠实 #4——不为这三个机械单包各造一个叶子）

### 新建应用叶子 cap（忠实 #4 全爆炸，一应用一叶子）

`software/`：`firefox` `tor-browser` `thunderbird` `qq` `feishu` `signal-desktop` `gimp` `typst` `kdenlive` `typora` `gnome-software` `remmina` `filezilla` `anki` `calibre` `xray` `sing-box` `v2rayn` `ghidra` `gnucash` `spotify` `vscode` `gemini-cli` `treefmt` `obs-studio` `osu-lazer` `hmcl` `mindustry` `ddnet` `vlc`

- `software/logseq` 保留现状。
- `vlc`（原 `development/base/system`）改为 `software/vlc` 用户叶子，不再塞开发能力。
- 单应用叶子按真实平台声明 `support.platform`：仅 Linux 的应用（`tor-browser` `qq` `feishu` `signal-desktop` `kdenlive` `typora` `gnome-software` `remmina` `filezilla` `v2rayn` `anki` `calibre` `ghidra` `gnucash` `osu-lazer` `hmcl` `mindustry` `ddnet` `vlc`）声明 `[ "linux" ]`；跨平台应用（`firefox` `thunderbird` `gimp` `typst` `spotify` `xray` `sing-box` `vscode` `gemini-cli` `treefmt` `obs-studio` `logseq`）声明 `[ "linux" "darwin" ]`。具体平台以 nixpkgs 实际可用性为准，实现时由测试与构建核定。
- `lib.optionals` 仅用于“概念跨平台、但含平台特定包”的系统叶子（如 `operations/system-diagnostics` 在 Linux 追加 `iotop`/`strace` 等），不再用于把单应用伪装成跨平台。

### 删除

- `modules/identity/rikki`（→ `systems/shared/users/rikki/default.nix`）
- `modules/development/base`、`modules/gaming/base`、`modules/software/workstation`（→ view）
- `modules/business/common`、`modules/lifetime/common`、`modules/software/base-cli`（弱语义）
- `modules/software/{browser,communication,creative,desktop-tools,learning,network-access,remote-access,reverse-engineering}`（→ 应用叶子）

### 服务能力净化（调和 realignment）

- `services/flatpak`：从模块默认值移除 28 项 Flatpak 应用清单，`packages` 默认改为 `[]`；清单迁入 `laptop-asus-tx4-personal` 宿主 `overrides` 的 `kaguya.services.flatpak.packages`。cap 仅保留 `enable` / `remotes` / `packages` 选项定义与 `flathub` 镜像默认 `remotes`，不再通过默认值决定“装哪些应用”。

## 宿主与用户实例目标形态

### `laptop-asus-tx4-personal`（linux / x86_64）

宿主 `meta.nix`：

- `views = [ "development/base" "gaming/base" ]`
- `caps = [ "desktop/gnome" "services/docker" "services/flatpak" "services/vm" "services/tailscale" "services/cups" "core/fonts" "core/input" "development/emacs" ]`
- `overrides`：保留 `kaguya.services.docker.storageDriver = "btrfs"`；新增 flatpak 应用清单（从 `services/flatpak` 模块默认值迁来）。

用户 `meta.nix`：

- `views = [ "development/base" "software/workstation" "gaming/base" ]`
- `caps = [ "core/user-cli" "software/firefox" "software/qq" "software/feishu" "software/signal-desktop" "software/kdenlive" "software/typora" "software/gnome-software" "software/remmina" "software/filezilla" "software/xray" "software/sing-box" "software/v2rayn" "software/anki" "software/calibre" "software/ghidra" "software/logseq" "software/gnucash" "software/spotify" ]`（`software/workstation` view 另供跨平台的 `thunderbird`/`gimp`/`typst`）

### `laptop-mbpM2`（darwin / aarch64）

宿主 `meta.nix`：

- `views = [ "development/base" ]`
- `caps = [ "development/emacs" "cross-platform/linux-builder" ]`

用户 `meta.nix`：

- `views = [ "development/base" "software/workstation" ]`
- `caps = [ "core/user-cli" "software/xray" "software/sing-box" "software/spotify" ]`（darwin 上的实际可安装子集，实现时按 nixpkgs 平台可用性核定；`software/workstation` view 另供 `thunderbird`/`gimp`/`typst`）
- **不选择 `software/firefox`**（替代当前 `kaguya.software.browser.enable = false` override）。
- **不选择 `software/vscode`**（替代当前 `kaguya.development.base.vscode.enable = false` override）。
- `overrides` 中两条旧开关一并删除。

> 说明：`software/workstation` view 在两台机器都不再包含浏览器；浏览器由用户实例显式选 `software/firefox` 决定。这正是“显式叶子选择”取代“聚合内部开关”的核心收益。

## 测试策略

### 新增

- `tests/view-graph.sh`：未知 view / 缺 facet / view 循环 / 平台不支持 / 正常展开。
- `tests/identity-placement.sh`：`systems/shared/users/rikki/default.nix` 存在；`modules/identity/` 无具名用户。
- `tests/module-leaf-audit.sh`：`modules/` 下无 `common`、无 `base`、无具名 identity。

### 修改

- `tests/software-capabilities.sh`：Darwin 不含 `firefox`、不启用 browser；Linux 经 `software/firefox` 叶子含 `firefox`；两端经 view 得到其余工作站应用。
- `tests/migration-equivalence.sh`：宿主/用户 `meta.nix` 含 `views`；旧 id（`identity/rikki`、`business/common`、`lifetime/common`、`software/workstation`、`development/base`、`gaming/base`）不再作为 `modules/` 目标。
- 改名波及：`tests/framework-smoke.sh` 等对 `buildPlan.systemCapabilities` → `systemCaps`、新增 `*Views` 的断言。

### 全量回归（必过）

`framework-smoke.sh`、`host-user-layout.sh`、`makefile-smoke.sh`、`deploy-smoke.sh`、`darwin-etc-compat.sh`、`migration-equivalence.sh`、`software-capabilities.sh`。

## 风险与取舍

1. **全爆炸粒度带来约 30 个单应用叶子**：样板量大；缓解——叶子内容极薄（仅 `enable` + 包列表），且宿主可读性由 view 维持。`bc/jq/fastfetch` 不爆炸，收进 `core/user-cli`。
2. **`requires` / `includes` 为静态展开**：平台差异不能放在聚合层，只能留在叶子内部用 `lib.optionals`。
3. **一次性改名无兼容层**：`capability` 标识全量替换；必须借助 `lsp` references 与测试确保无遗漏，避免运行期 eval 才暴露。
4. **`views/` 引入新框架子系统**：解析器、错误类型、数据模型均需测试先行（`view-graph.sh`）。
5. **身份迁移**：共享身份只能落在 `systems/` 层，不得再包装成“共享 identity 模块”。

## 取代的文档

本设计取代并应在实施收尾时把以下文档标记为 superseded：

- `docs/superpowers/specs/2026-04-08-software-capability-refactor-design.md`
- `docs/superpowers/plans/2026-04-08-software-capability-refactor.md`
- `docs/superpowers/plans/2026-04-08-capability-architecture-realignment.md`
- `docs/superpowers/plans/2026-04-08-development-base-split.md`
- `docs/superpowers/specs/2026-04-09-leaf-modules-and-views-design.md`
- `docs/superpowers/plans/2026-04-09-leaf-modules-and-views-migration.md`
