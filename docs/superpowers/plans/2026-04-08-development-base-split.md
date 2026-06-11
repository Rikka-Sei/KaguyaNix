# Development Base Split Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 拆分 `modules/development/base` 中过于混杂的职责边界，并让 `laptop-mbpM2` 不再通过共享软件聚合自动安装 `firefox`。

**Architecture:** 采用“保留聚合入口 + 拆出语义明确的叶子 capability”策略。`development/base` 不再直接承载大包列表，而只做兼容入口与依赖聚合；同时将浏览器选择从 `software/workstation` 中解耦，使 `M2` 可以不启用 `firefox` 而不依赖包级特判。

**Tech Stack:** Nix, Home Manager, nix-darwin, NixOS, Bash 测试脚本

---

## 当前问题

### 1. `development/base/system` 边界过大

当前 [modules/development/base/system/module.nix](/Users/rikki/WorkSpace/KaguyaNix/modules/development/base/system/module.nix) 同时包含：

- 开发工具链：`git` `gnumake` `alejandra` `nil` `nixfmt-rfc-style`
- 通用 CLI / 压缩工具：`curl` `wget` `zip` `unzip` `tree` `file`
- 网络诊断：`mtr` `iperf3` `dnsutils` `nmap` `ipcalc`
- 系统诊断：`iotop` `strace` `ltrace` `lm_sensors` `pciutils`
- 其他杂项：`mailutils` `cowsay` `vlc`

这已经不是“基础开发能力”，而是“开发 + 运维 + 基础工具 + 一些日常包”的集合。

### 2. `development/base/user` 仍偏胖，但问题较轻

当前 [modules/development/base/user/module.nix](/Users/rikki/WorkSpace/KaguyaNix/modules/development/base/user/module.nix) 主要包含：

- 开发用户态工具：`treefmt` `gemini-cli` `vscode`
- 本地脚本投放
- `fish` 别名
- `starship`

它仍然有拆分空间，但比 `system` facet 更接近“开发用户环境引导”。

### 3. `software/workstation` 目前强绑定 `software/browser`

当前 [modules/software/workstation/user/meta.nix](/Users/rikki/WorkSpace/KaguyaNix/modules/software/workstation/user/meta.nix) 通过 `requires` 固定依赖 `software/browser`，而 [modules/software/browser/user/module.nix](/Users/rikki/WorkSpace/KaguyaNix/modules/software/browser/user/module.nix) 默认安装 `firefox`。因此 `laptop-mbpM2` 即使不希望由 Nix 管理浏览器，也会被动获得 `firefox`。

## 目标结构

### A. `development/base/system` 变成聚合能力

保留 `development/base/system` 作为兼容入口，但自身不再直接声明大包列表，而改为 `requires`：

- `development/toolchain`
- `development/assistant`
- `core/cli-utils`
- `operations/network-tools`
- `operations/system-diagnostics`

### B. 叶子 capability 建议

#### `development/toolchain/system`

负责真正的开发工具链：

- `git`
- `gnumake`
- `alejandra`
- `nil`
- `nixfmt-rfc-style`
- `nix-output-monitor`
- `programs.direnv.enable = true`

#### `development/assistant/system`

负责 AI / 辅助开发入口：


#### `core/cli-utils/system`

负责通用 CLI 基线：

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

#### `operations/network-tools/system`

负责网络排障与传输：

- `mtr`
- `iperf3`
- `dnsutils`
- `aria2`
- `nmap`
- `ipcalc`
- `netcat-gnu`

#### `operations/system-diagnostics/system`

负责系统排障与硬件观察：

- `btop`
- `iftop`
- `lsof`
- Linux: `iotop` `strace` `ltrace` `sysstat` `lm_sensors` `ethtool` `pciutils` `usbutils` `mission-center`

### C. `vlc` 从 `development/base` 中移除

`vlc` 不应再属于 `development/base/system`。推荐顺序：

1. 先从 `development/base/system` 删除
2. 如果仍需保留，单独建模为 `software/media` 或放回宿主机局部配置

### D. `development/base/user` 分两阶段处理

#### 第一阶段

保留 `development/base/user` 作为用户态聚合入口，暂不大拆，只做小范围清理：

- 保留脚本投放
- 保留 `treefmt`
- 保留 `gemini-cli`
- `vscode` 继续作为显式选项

#### 第二阶段

如继续细化，再拆为：

- `development/editor-vscode/user`
- `development/cli-agents/user`
- `development/scripts/user`
- `shell/common/user` 或 `shell/fish-common/user`

当前不建议把用户态也一次性拆到很碎，以免同时动到过多 shell 偏好与脚本路径逻辑。

## `M2` 上移除 Firefox 的推荐做法

### 推荐方案

将 `software/browser` 从 `software/workstation` 的 `requires` 中移除，改为由宿主机显式选择是否启用。

这样调整后：

- Linux 宿主机继续显式启用 `software/browser`
- `laptop-mbpM2` 不启用 `software/browser`
- `software/workstation` 只表示“桌面工作站基础软件”，不再强绑定某个浏览器选择

### 不推荐方案

直接给 `software/browser` 增加 `firefox.enable = false` 的宿主机 override。

原因：

- 这会把“是否需要浏览器 capability”退化成“capability 已启用，但包内某个子项关掉”
- 语义上不如“宿主机显式不声明该 capability”清晰

## 实施顺序

## Chunk 1: 先写测试

### Task 1: 固化 `M2` 无 Firefox 的预期

**Files:**
- Modify: `tests/software-capabilities.sh`

- [ ] **Step 1: 修改 Darwin 包列表断言**

将 `laptop-mbpM2` 的断言改为：

- 不包含 `firefox`
- 仍保留 `thunderbird`
- 仍不包含 `vscode`

- [ ] **Step 2: 跑测试确认当前实现失败**

Run: `./tests/software-capabilities.sh`
Expected: FAIL，因为当前 `software/workstation` 仍会引入 `software/browser`

### Task 2: 增加 `development/base` 边界测试

**Files:**
- Create: `tests/development-capabilities.sh`

- [ ] **Step 1: 新增 system capability 展开断言**

至少断言：

- `development/base` 展开后包含新的叶子 capability
- Linux 仍保留关键开发工具链
- `vlc` 不再由 `development/base` 提供

- [ ] **Step 2: 运行测试确认失败**

Run: `./tests/development-capabilities.sh`
Expected: FAIL，因为当前拆分尚未实施

## Chunk 2: 解开浏览器与工作站聚合

### Task 3: 调整软件 capability 结构

**Files:**
- Modify: `modules/software/workstation/user/meta.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`

- [ ] **Step 1: 从 `software/workstation` 的 `requires` 中删除 `software/browser`**

- [ ] **Step 2: 在 Linux 宿主机显式添加 `software/browser`**

- [ ] **Step 3: Darwin 宿主机不再声明 `software/browser`**

- [ ] **Step 4: 运行软件 capability 测试**

Run: `./tests/software-capabilities.sh`
Expected: PASS

## Chunk 3: 拆分 `development/base/system`

### Task 4: 新建叶子 capability

**Files:**
- Create: `modules/development/toolchain/system/meta.nix`
- Create: `modules/development/toolchain/system/module.nix`
- Create: `modules/development/assistant/system/meta.nix`
- Create: `modules/development/assistant/system/module.nix`
- Create: `modules/core/cli-utils/system/meta.nix`
- Create: `modules/core/cli-utils/system/module.nix`
- Create: `modules/operations/network-tools/system/meta.nix`
- Create: `modules/operations/network-tools/system/module.nix`
- Create: `modules/operations/system-diagnostics/system/meta.nix`
- Create: `modules/operations/system-diagnostics/system/module.nix`

- [ ] **Step 1: 先写 `meta.nix`**

为每个 capability 写清：

- `optionPath`
- `support.platform`
- `support.arch`
- `requires`
- `conflicts`

- [ ] **Step 2: 再写 `module.nix`**

只放对应边界的软件与系统配置，不做跨职责混装。

### Task 5: 将 `development/base/system` 改成聚合入口

**Files:**
- Modify: `modules/development/base/system/meta.nix`
- Modify: `modules/development/base/system/module.nix`

- [ ] **Step 1: 用 `requires` 指向叶子 capability**

- [ ] **Step 2: 从 `module.nix` 移除大包列表**

- [ ] **Step 3: 仅保留必要兼容选项，或将选项迁移到合适的叶子 capability**

- [ ] **Step 4: 处理 `vlc` 的迁出**

若暂无新的复用落点，先从 `development/base` 删除并记录为宿主机局部或后续 capability。

## Chunk 4: 清理 `development/base/user`

### Task 6: 做最小清理，不一次拆碎

**Files:**
- Modify: `modules/development/base/user/module.nix`
- Modify: `modules/development/base/user/meta.nix`

- [ ] **Step 1: 保持用户态仍可作为聚合入口**

- [ ] **Step 2: 确认 `vscode` 选项仍可被 `laptop-mbpM2` 的 `overrides` 关闭**

- [ ] **Step 3: 不在这一轮引入 `shell/*` 大重构**

## Chunk 5: 文档与回归

### Task 7: 更新 README / AGENTS 的示例与说明

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 更新 capability 示例**

- [ ] **Step 2: 补充 `development/base` 的新组织说明**

### Task 8: 执行完整验证

**Files:**
- Modify: None

- [ ] **Step 1: 运行新增测试**

Run: `./tests/development-capabilities.sh`
Expected: PASS

- [ ] **Step 2: 运行现有回归测试**

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

## 风险与注意事项

1. 当前工作区已有较多未清理的格式化 diff，实施前应先压缩无关改动，避免评审面过大。
2. `development/base/system` 如果一次拆得过碎，会带来 capability 爆炸；因此这份计划只建议拆出 5 个边界最清晰的叶子 capability。
3. `vlc` 的归属不是开发能力，实施时应明确选择“迁出”而不是继续临时塞回其他开发 capability。
