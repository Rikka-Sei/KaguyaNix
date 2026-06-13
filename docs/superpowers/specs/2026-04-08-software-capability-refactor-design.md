# 软件 Capability 重构设计

> **SUPERSEDED**：由 docs/superpowers/specs/2026-06-11-cap-view-architecture-design.md 及其计划 2026-06-11-cap-view-architecture.md 取代。

## 背景

原 `modules/software/common/user/module.nix` 实际上是旧 `users/rikki/profiles/software.nix` 在 capability 化后的直接迁移结果。结构已经切换到 capability 模型，但语义边界仍然停留在“共享软件大包”阶段。

这带来三个问题：

1. `software/common` 同时混合 CLI 工具、浏览器、通信软件、网络接入、创作软件、学习工具、逆向分析工具和游戏相关包，已经不再表示单一能力。
2. 宿主机用户 `meta.nix` 的 capability 列表虽然简短，但真实语义被折叠进一个不可解释的 capability 中，阅读和维护成本高。
3. 现有 capability 图支持 `requires` / `conflicts`，但软件能力尚未真正利用这一层组合关系。

## 目标

1. 移除 `software/common` 这一语义空泛的聚合能力。
2. 将用户态软件按“用途明确、可复用”的能力边界重新组织。
3. 保持宿主机 capability 列表可读，不走“每个包一个 capability”的极端原子化路径。
4. 将明显属于其他领域的内容移回原领域，例如游戏相关包回收到 `gaming/base`。
5. 在 README 中补全 `meta.nix` 各字段的职责说明，降低框架使用门槛。

## 非目标

1. 不引入新的顶层模型，不恢复旧的 profile 体系。
2. 不改动 capability 图核心机制。
3. 不追求一次性把所有用户软件都拆成单包 capability。

## 设计原则

### 1. 共享的是能力，不是个人机器上的软件清单

capability 应表达“用途”或“责任边界”，而不是“当前机器上经常安装的一坨包”。

### 2. 使用两层组织

第一层是语义明确的叶子 capability；第二层是少量聚合 capability，通过 `requires` 组合叶子能力。

### 3. 平台差异尽量留在叶子 capability 内部

由于 `requires` 是静态展开的，不能按平台条件选择依赖。因此聚合 capability 只依赖跨平台存在的能力；具体包的 Linux / Darwin 差异在叶子 capability 内通过 `lib.optionals` 处理。

### 4. 已有领域优先复位

如果某个软件明显属于既有 capability 域，应优先回归原领域，而不是继续堆入 `software/*`。

## 拆分方案

第一轮将 `software/common` 拆为以下 capability：

### 聚合 capability

- `software/workstation`
  - 不直接声明 `home.packages`
  - 通过 `requires` 聚合下列基础桌面能力：
    - `software/base-cli`
    - `software/browser`
    - `software/communication`
    - `software/creative`
    - `software/desktop-tools`
    - `software/remote-access`

### 叶子 capability

- `software/base-cli`
  - `bc`
  - `jq`
  - `fastfetch`

- `software/browser`
  - 跨平台：`firefox`
  - Linux：`tor-browser`

- `software/communication`
  - 跨平台：`thunderbird`
  - Linux：`qq` `feishu` `signal-desktop`

- `software/creative`
  - 跨平台：`gimp` `typst`
  - Linux：`kdePackages.kdenlive` `typora`

- `software/desktop-tools`
  - Linux：`gnome-software`

- `software/remote-access`
  - Linux：`remmina` `filezilla`

- `software/network-access`
  - 跨平台：`xray` `sing-box`
  - Linux：`v2rayn`

- `software/learning`
  - Linux：`anki` `calibre`

- `software/reverse-engineering`
  - Linux：`ghidra` `ghidra-extensions.ghidra-golanganalyzerextension`

- `software/logseq`
  - 保持现状

## 跨域回收

将以下包从软件域移回游戏域：

- `hmcl`
- `mindustry`
- `ddnet`

更新后，`gaming/base` 负责：

- 原有 `obs-studio`
- Linux 的 `osu-lazer-bin`
- Linux 的 `hmcl`
- Linux 的 `mindustry`
- Linux 的 `ddnet`

## 宿主机 capability 组织

Linux 用户：

- `identity/rikki`
- `development/base`
- `software/workstation`
- `software/network-access`
- `software/learning`
- `software/logseq`
- `software/reverse-engineering`
- `gaming/base`
- `business/common`
- `lifetime/common`

Darwin 用户：

- `identity/rikki`
- `development/base`
- `software/workstation`
- `software/network-access`
- `business/common`
- `lifetime/common`

其中 `laptop-mbpM2` 通过用户实例 `overrides` 关闭 `kaguya.development.base.vscode.enable`，避免与宿主机外部安装的 VSCode 重复。

## README 补充内容

README 需要补充三类 `meta.nix` 的字段说明：

### 1. 宿主机 `systems/<host>/meta.nix`

- `target.platform`
- `target.arch`
- `hardware`
- `locale`
- `capabilities`
- `users`

### 2. 用户 `systems/<host>/users/<name>/meta.nix`

- `enable`
- `admin`
- `shell`
- `extraGroups`
- `capabilities`
- `overrides`
- `stateVersion`
- `homeDirectory`

### 3. capability facet `modules/<domain>/<name>/{system,user}/meta.nix`

- `optionPath`
- `support.platform`
- `support.arch`
- `requires`
- `conflicts`

## 验证策略

1. 先修改测试，表达新的 capability 结构与软件归属预期。
2. 运行相关测试，确认在当前实现下失败。
3. 实现重构后重新运行：
   - `./tests/framework-smoke.sh`
   - `./tests/host-user-layout.sh`
   - `./tests/migration-equivalence.sh`
   - `./tests/cleanup-check.sh`
   - `./tests/makefile-smoke.sh`
   - `./tests/deploy-smoke.sh`
   - `./tests/software-capabilities.sh`
   - `./tests/darwin-etc-compat.sh`

## 风险与取舍

1. capability 数量会上升，但宿主机可读性会通过 `software/workstation` 聚合层保持在可接受范围内。
2. `requires` 为静态关系，意味着平台差异不能放在聚合层，只能留在叶子能力内部。
3. README 字段说明的补充不会自动形成约束，仍需依赖测试与代码审查维持一致性。
