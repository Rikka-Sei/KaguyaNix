# Capability Architecture Realignment Implementation Plan

> **SUPERSEDED**：由 docs/superpowers/specs/2026-06-11-cap-view-architecture-design.md 及其计划 2026-06-11-cap-view-architecture.md 取代。

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 KaguyaNix 的 capability graph 架构重新整理 `modules/`，消除人名模块承载通用逻辑、`common` / `base` 大包化、服务模块混入内容清单等问题，并让宿主机与用户实例只声明真正可解释的能力。

**Architecture:** 采用“三层 capability”模型：叶子能力负责单一实现，聚合能力只通过 `requires` 组合，身份预设能力只承载个人默认值而不定义通用行为。保留稳定的顶层 domain，减少新的分类负担；通过逐步迁移而非一次性改名，先处理边界最坏的模块，再处理宿主机和文档收口。

**Tech Stack:** Nix, Home Manager, nix-darwin, NixOS, Bash 测试脚本

---

## 目标架构

### 1. Capability 角色模型

#### 叶子能力

叶子能力必须满足：

- 只表达一个清晰职责
- 可以直接拥有 `environment.systemPackages`、`home.packages`、`programs.*`、`services.*`
- 不再用 `common` 这类语义空名字掩盖内容

示例：

- `services/docker`
- `core/input`
- `development/toolchain`
- `software/browser`

#### 聚合能力

聚合能力必须满足：

- 只负责表达“某一层的默认组合”
- 默认不直接声明包列表
- 主要通过 `requires` 组合叶子能力

示例：

- `development/base`
- `software/workstation`
- `gaming/base`

#### 身份预设能力

身份预设能力必须满足：

- 只表达“某个人的长期默认值”
- 不定义通用 schema
- 不承担通用行为实现

示例：

- `identity/rikki`

### 2. Domain 规划

为减少理解负担，本次重构不引入过多新 domain，而是收敛到稳定的顶层职责：

- `core/`：跨系统或跨用户的基础能力与通用配置
- `desktop/`：桌面环境与桌面集成
- `services/`：系统服务与基础设施
- `cross-platform/`：跨平台桥接能力
- `development/`：开发工具链、编辑器、脚本、助手
- `gaming/`：游戏运行栈与游戏用户工具
- `software/`：用户态应用能力
- `identity/`：个人身份与默认值预设

### 3. 命名规则

- 禁止新增 `common`
- `base` 仅允许用于聚合能力或兼容入口
- 人名 capability 仅允许出现在 `identity/`
- 用户态应用尽量收敛到 `software/`，不再继续扩散出 `business/`、`lifetime/` 一类弱语义 domain
- 服务模块不得内置大规模应用清单

## 模块处置总览

### 立即重构

- `modules/development/base`
- `modules/identity/rikki`
- `modules/services/flatpak`
- `modules/business/common`
- `modules/lifetime/common`
- `modules/software/base-cli`
- `modules/software/workstation`

### 中期观察，但本轮暂不拆

- `modules/desktop/gnome`
- `modules/core/fonts`
- `modules/gaming/base`
- `modules/services/vm`

这些模块内部仍然偏厚，但整体职责尚可解释，且与当前问题相比优先级较低。

### 基本健康，维持现状

- `modules/core/command-not-found`
- `modules/core/input`
- `modules/cross-platform/linux-builder`
- `modules/services/docker`
- `modules/services/tailscale`
- `modules/services/cups`
- `modules/services/teamviewer`
- `modules/services/virtualbox`
- `modules/services/vmware`
- `modules/development/emacs`
- `modules/software/browser`
- `modules/software/communication`
- `modules/software/creative`
- `modules/software/network-access`
- `modules/software/remote-access`
- `modules/software/learning`
- `modules/software/logseq`
- `modules/software/reverse-engineering`

## 目标模块地图

### 保留并重塑的能力

- `development/base`
  - 保留为聚合入口
  - 不再直接承载大包列表
- `identity/rikki`
  - 保留为纯身份预设
  - 不再声明通用 Git schema
- `software/workstation`
  - 保留为用户桌面软件聚合能力
  - 不再默认强绑浏览器

### 新增能力

- `core/git/user`
- `core/user-cli/user`
- `development/toolchain/system`
- `development/assistant/system`
- `development/editor-vscode/user`
- `development/cli-agents/user`
- `development/scripts/user`
- `operations/network-tools/system`
- `operations/system-diagnostics/system`
- `software/accounting/user`
- `software/music/user`

### 删除能力

- `business/common`
- `lifetime/common`
- `software/base-cli`

## 宿主机与用户实例的目标关系

### Linux 样例宿主机

`systems/laptop-asus-tx4-personal/meta.nix`：

- 继续保留系统能力：
  - `desktop/gnome`
  - `services/docker`
  - `services/flatpak`
  - `services/vm`
  - `services/tailscale`
  - `services/cups`
  - `core/fonts`
  - `core/input`
  - `development/base`
  - `development/emacs`
  - `gaming/base`

`systems/laptop-asus-tx4-personal/users/rikki/meta.nix`：

- 改为显式声明：
  - `identity/rikki`
  - `development/base`
  - `core/user-cli`
  - `software/workstation`
  - `software/browser`
  - `software/network-access`
  - `software/learning`
  - `software/logseq`
  - `software/reverse-engineering`
  - `software/accounting`
  - `software/music`
  - `gaming/base`

### Darwin 样例宿主机

`systems/laptop-mbpM2/meta.nix`：

- 继续保留：
  - `development/base`
  - `development/emacs`
  - `cross-platform/linux-builder`

`systems/laptop-mbpM2/users/rikki/meta.nix`：

- 改为显式声明：
  - `identity/rikki`
  - `development/base`
  - `core/user-cli`
  - `software/workstation`
  - `software/network-access`
  - `software/music`

补充约束：

- `laptop-mbpM2` 不再启用 `software/browser`
- `laptop-mbpM2` 继续通过 `overrides` 关闭 `kaguya.development.editor-vscode.enable`

## 实施顺序

## Chunk 1: 建立架构护栏

### Task 1: 补齐文档中的 capability 角色与命名规则

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 在 README 中新增 capability 角色定义**

写明：

- 什么是叶子能力
- 什么是聚合能力
- 什么是身份预设能力

- [ ] **Step 2: 在 README 中新增命名规则**

写明：

- 禁止新增 `common`
- `base` 仅用于聚合
- 人名 capability 仅用于身份预设
- 服务模块不承载应用目录

- [ ] **Step 3: 同步 AGENTS 示例**

将示例 capability 列表改成新的架构风格，避免继续传播旧例子。

### Task 2: 先写失败测试，冻结目标边界

**Files:**
- Create: `tests/capability-architecture.sh`
- Modify: `tests/software-capabilities.sh`
- Modify: `tests/migration-equivalence.sh`

- [ ] **Step 1: 新增架构测试**

`tests/capability-architecture.sh` 至少断言：

- `modules/business/common` 不再作为目标能力
- `modules/lifetime/common` 不再作为目标能力
- `modules/software/base-cli` 不再作为目标能力
- `modules/development/base/system/meta.nix` 最终应包含非空 `requires`
- `modules/services/flatpak/system/module.nix` 不应继续硬编码 `com.google.Chrome`
- `modules/identity/rikki/user/module.nix` 不应继续定义通用 `kaguya.programs.git` schema

- [ ] **Step 2: 更新软件能力测试**

把 Darwin 的浏览器预期改为：

- 不包含 `firefox`
- 不启用 `software/browser`

同时把 `business/common`、`lifetime/common` 的预期迁移到新能力：

- `software/accounting`
- `software/music`

- [ ] **Step 3: 更新迁移测试**

让 `migration-equivalence` 断言宿主机用户实例改用新的能力集合。

- [ ] **Step 4: 运行测试确认失败**

Run: `./tests/capability-architecture.sh`
Expected: FAIL，因为模块结构尚未调整

Run: `./tests/software-capabilities.sh`
Expected: FAIL，因为 `laptop-mbpM2` 当前仍会从 `software/workstation` 获得 `firefox`

Run: `./tests/migration-equivalence.sh`
Expected: FAIL，因为宿主机 capability 尚未迁移到新命名

## Chunk 2: 抽离通用 Git 行为，净化身份能力

### Task 3: 新建通用 Git 能力

**Files:**
- Create: `modules/core/git/user/meta.nix`
- Create: `modules/core/git/user/module.nix`

- [ ] **Step 1: 写 `meta.nix`**

定义：

- `optionPath = [ "kaguya" "core" "git" ]`
- 正确平台与架构支持
- 默认空 `conflicts`

- [ ] **Step 2: 写 `module.nix`**

负责：

- 定义通用 Git 相关 `kaguya.*` 选项
- 把这些选项映射到 `programs.git`

- [ ] **Step 3: 不带任何 Rikki 默认值**

该模块只表达通用行为，不写死个人邮箱、签名 key 或用户名。

### Task 4: 将 `identity/rikki` 改成纯预设

**Files:**
- Modify: `modules/identity/rikki/user/meta.nix`
- Modify: `modules/identity/rikki/user/module.nix`

- [ ] **Step 1: 在 `meta.nix` 中声明依赖 `core/git`**

- [ ] **Step 2: 从 `module.nix` 中删除通用 Git schema 定义**

- [ ] **Step 3: 仅保留默认值注入**

只保留：

- `userName`
- `email`
- `signingKey`
- `signCommits`
- `lfs`

- [ ] **Step 4: 运行相关测试**

Run: `./tests/capability-architecture.sh`
Expected: 相关 identity 断言变为 PASS

## Chunk 3: 收敛用户应用域，清理 `common`

### Task 5: 将 `business/common` 迁移为 `software/accounting`

**Files:**
- Create: `modules/software/accounting/user/meta.nix`
- Create: `modules/software/accounting/user/module.nix`
- Delete: `modules/business/common/user/meta.nix`
- Delete: `modules/business/common/user/module.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 新建 `software/accounting`**

迁移 `gnucash`，保持 Linux 限定。

- [ ] **Step 2: 宿主机用户实例改用 `software/accounting`**

- [ ] **Step 3: 清理 `business/common` 的所有引用**

### Task 6: 将 `lifetime/common` 迁移为 `software/music`

**Files:**
- Create: `modules/software/music/user/meta.nix`
- Create: `modules/software/music/user/module.nix`
- Delete: `modules/lifetime/common/user/meta.nix`
- Delete: `modules/lifetime/common/user/module.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 新建 `software/music`**

迁移 `spotify`。

- [ ] **Step 2: 宿主机用户实例改用 `software/music`**

- [ ] **Step 3: 清理 `lifetime/common` 的所有引用**

### Task 7: 将 `software/base-cli` 迁移为 `core/user-cli`

**Files:**
- Create: `modules/core/user-cli/user/meta.nix`
- Create: `modules/core/user-cli/user/module.nix`
- Delete: `modules/software/base-cli/user/meta.nix`
- Delete: `modules/software/base-cli/user/module.nix`
- Modify: `modules/software/workstation/user/meta.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`

- [ ] **Step 1: 新建 `core/user-cli`**

迁移：

- `bc`
- `jq`
- `fastfetch`

- [ ] **Step 2: 从 `software/workstation` 中移除 `software/base-cli` 引用**

- [ ] **Step 3: 由宿主机用户实例显式启用 `core/user-cli`**

## Chunk 4: 解开 `software/workstation` 的错误组合

### Task 8: 让浏览器变成显式选择，而不是工作站默认

**Files:**
- Modify: `modules/software/workstation/user/meta.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`
- Modify: `tests/software-capabilities.sh`

- [ ] **Step 1: 从 `software/workstation` 的 `requires` 中删除 `software/browser`**

- [ ] **Step 2: Linux 用户实例显式添加 `software/browser`**

- [ ] **Step 3: Darwin 用户实例不声明 `software/browser`**

- [ ] **Step 4: 跑软件能力测试**

Run: `./tests/software-capabilities.sh`
Expected: PASS，Darwin 不再包含 `firefox`

### Task 9: 重新定义 `software/workstation`

**Files:**
- Modify: `modules/software/workstation/user/meta.nix`
- Modify: `modules/software/workstation/user/module.nix`

- [ ] **Step 1: 明确 `software/workstation` 只是桌面工作站应用组合**

它只聚合：

- `software/communication`
- `software/creative`
- `software/desktop-tools`
- `software/remote-access`

- [ ] **Step 2: 不再让它偷偷决定网络、浏览器、学习或专业工具**

这些能力全部由宿主机用户实例显式声明。

## Chunk 5: 拆分 `development/base/system`

### Task 10: 新建系统侧叶子能力

**Files:**
- Create: `modules/development/toolchain/system/meta.nix`
- Create: `modules/development/toolchain/system/module.nix`
- Create: `modules/development/assistant/system/meta.nix`
- Create: `modules/development/assistant/system/module.nix`
- Create: `modules/operations/network-tools/system/meta.nix`
- Create: `modules/operations/network-tools/system/module.nix`
- Create: `modules/operations/system-diagnostics/system/meta.nix`
- Create: `modules/operations/system-diagnostics/system/module.nix`
- Create: `modules/core/cli-utils/system/meta.nix`
- Create: `modules/core/cli-utils/system/module.nix`

- [ ] **Step 1: 写 `development/toolchain`**

迁移：

- `git`
- `gnumake`
- `alejandra`
- `nil`
- `nixfmt-rfc-style`
- `nix-output-monitor`
- `programs.direnv.enable = true`

- [ ] **Step 2: 写 `development/assistant`**

迁移：


- [ ] **Step 3: 写 `core/cli-utils`**

迁移：

- `axel`
- `nano`
- `vim`
- `wget`
- `curl`
- `zip`
- `xz`
- `unzip`
- `p7zip`
- `ripgrep`
- `file`
- `which`
- `tree`
- `gnused`
- `gnutar`
- `gawk`
- `zstd`
- `cowsay`
- `mailutils`

- [ ] **Step 4: 写 `operations/network-tools`**

迁移：

- `mtr`
- `iperf3`
- `dnsutils`
- `aria2`
- `nmap`
- `ipcalc`
- `netcat-gnu`

- [ ] **Step 5: 写 `operations/system-diagnostics`**

迁移：

- `btop`
- `iftop`
- `lsof`
- Linux: `iotop` `strace` `ltrace` `sysstat` `lm_sensors` `ethtool` `pciutils` `usbutils` `mission-center`

### Task 11: 将 `development/base/system` 改为 bundle

**Files:**
- Modify: `modules/development/base/system/meta.nix`
- Modify: `modules/development/base/system/module.nix`

- [ ] **Step 1: 在 `meta.nix` 中写入 `requires`**

依赖：

- `development/toolchain`
- `development/assistant`
- `core/cli-utils`
- `operations/network-tools`
- `operations/system-diagnostics`

- [ ] **Step 2: 删除大包列表实现**

- [ ] **Step 3: 从 `development/base/system` 中移除 `vlc`**

如果仍需要，后续应迁入 `software/*` 或宿主机局部配置，不再留在开发 bundle 中。

## Chunk 6: 拆分 `development/base/user`

### Task 12: 新建用户侧叶子能力

**Files:**
- Create: `modules/development/editor-vscode/user/meta.nix`
- Create: `modules/development/editor-vscode/user/module.nix`
- Create: `modules/development/cli-agents/user/meta.nix`
- Create: `modules/development/cli-agents/user/module.nix`
- Create: `modules/development/scripts/user/meta.nix`
- Create: `modules/development/scripts/user/module.nix`

- [ ] **Step 1: 写 `development/editor-vscode`**

迁移 `vscode`，并保留 `enable` 选项。

- [ ] **Step 2: 写 `development/cli-agents`**

迁移：

- `gemini-cli`
- 如有必要，保留 `treefmt` 或将其放回 `development/toolchain`

- [ ] **Step 3: 写 `development/scripts`**

迁移：

- `home.file = deployScripts`
- `home.sessionPath`

### Task 13: 将 `development/base/user` 改为轻量聚合入口

**Files:**
- Modify: `modules/development/base/user/meta.nix`
- Modify: `modules/development/base/user/module.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`

- [ ] **Step 1: 在 `meta.nix` 中写入 `requires`**

依赖：

- `development/editor-vscode`
- `development/cli-agents`
- `development/scripts`

- [ ] **Step 2: 只保留真正还属于 bundle 的内容**

仅保留暂时不值得再拆的新手工作流配置，例如：

- `programs.fish.shellAliases`
- `programs.starship.enable`

- [ ] **Step 3: 宿主机覆写改到新的选项路径**

把 `laptop-mbpM2` 的覆写从：

- `kaguya.development.base.vscode.enable = false`

迁移为：

- `kaguya.development.editor-vscode.enable = false`

## Chunk 7: 让 `services/flatpak` 只负责服务，不负责应用目录

### Task 14: 收缩 Flatpak 服务能力

**Files:**
- Modify: `modules/services/flatpak/system/module.nix`
- Modify: `systems/laptop-asus-tx4-personal/meta.nix`
- Modify: `tests/capability-architecture.sh`

- [ ] **Step 1: 从 `modules/services/flatpak/system/module.nix` 中移除长默认应用列表**

- [ ] **Step 2: 将当前 Linux 宿主机的 Flatpak 默认应用列表迁移到宿主机 `overrides`**

使用：

- `kaguya.services.flatpak.packages = [ ... ]`
- `kaguya.services.flatpak.remotes = [ ... ]`

- [ ] **Step 3: 保证 `services/flatpak` 只负责基础设施**

该 capability 只保留：

- `services.flatpak.enable`
- `remotes`
- `packages` 选项定义

不再通过模块默认值表达“这台机器应该装哪些应用”。

## Chunk 8: 中优先级审计，不立即大拆

### Task 15: 为暂缓模块建立审计清单

**Files:**
- Modify: `README.md`
- Create: `docs/superpowers/specs/2026-04-08-capability-architecture-audit.md`

- [ ] **Step 1: 记录 `desktop/gnome` 的待观察问题**

关注：

- GNOME 基础启用
- GNOME 扩展
- 桌面附加工具

- [ ] **Step 2: 记录 `core/fonts` 的待观察问题**

关注：

- 字体包
- locale 默认值
- bindfs 字体映射

- [ ] **Step 3: 记录 `gaming/base` 的待观察问题**

关注：

- system 与 user facet 是否需要拆叶子能力
- 是否继续保留 `base` 作为聚合入口

- [ ] **Step 4: 记录 `services/vm` 的待观察问题**

关注：

- libvirt 运行栈
- GUI 工具
- 附属系统包

## Chunk 9: 验证与收尾

### Task 16: 运行新增与既有测试

**Files:**
- Modify: None

- [ ] **Step 1: 运行新增架构测试**

Run: `./tests/capability-architecture.sh`
Expected: PASS

- [ ] **Step 2: 运行既有回归测试**

Run: `./tests/framework-smoke.sh`
Expected: PASS

Run: `./tests/host-user-layout.sh`
Expected: PASS

Run: `./tests/migration-equivalence.sh`
Expected: PASS

Run: `./tests/cleanup-check.sh`
Expected: PASS

Run: `./tests/makefile-smoke.sh`
Expected: PASS

Run: `./tests/deploy-smoke.sh`
Expected: PASS

Run: `./tests/software-capabilities.sh`
Expected: PASS

Run: `./tests/darwin-etc-compat.sh`
Expected: PASS

### Task 17: 清理兼容层与无用目录

**Files:**
- Modify: None

- [ ] **Step 1: 删除空目录**

确认删除：

- `modules/business/common`
- `modules/lifetime/common`
- `modules/software/base-cli`

- [ ] **Step 2: 清理文档与测试中的旧 capability 引用**

确保不再残留：

- `business/common`
- `lifetime/common`
- `software/base-cli`

- [ ] **Step 3: 压缩无关格式化 diff**

若工作区存在与本次架构迁移无关的纯格式变更，应在最终提交前清理。

## 风险控制

1. 不要一次性引入太多新 top-level domain，因此本计划只新增 `operations/`，其他能力尽量收纳进现有 domain。
2. 不要把所有用户态包继续拆成更细的软件分类；用户态应用统一收敛到 `software/`，减少理解负担。
3. 不要让 bundle 模块继续偷偷承载包列表，否则 `base` / `workstation` 会再次膨胀。
4. 不要让人名模块定义通用选项，否则 `identity/rikki` 的问题会在别的人名模块上重复出现。
5. 服务 capability 与宿主机应用偏好必须分离；`services/flatpak` 是本轮最典型的修复点。
