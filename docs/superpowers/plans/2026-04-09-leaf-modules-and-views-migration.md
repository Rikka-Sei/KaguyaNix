# Leaf Modules And Views Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 KaguyaNix 重构为“`modules/` 只承载叶子能力、`views/` 承载聚合视图、用户身份回到 `systems/`”的清晰架构。

**Architecture:** 先在框架层增加 `views/` 支持与新的 `meta.nix` 数据模型，再分波次迁移现有聚合模块、身份模块和弱语义软件模块。第一波修复结构边界，第二波把混装的软件分类替换为应用名叶子，第三波清理文档、测试和遗留目录。

**Tech Stack:** Nix, Home Manager, nix-darwin, NixOS, Bash 测试脚本

---

## 文件结构总览

### 新增目录

- Create: `views/development/base/`
- Create: `views/gaming/base/`
- Create: `views/software/workstation/`
- Create: `systems/shared/users/rikki/`

### 框架文件

- Modify: `lib/capabilityGraph.nix`
- Modify: `lib/errors.nix`
- Modify: `parts/systems.nix`
- Modify: `README.md`
- Modify: `AGENTS.md`

### 目标删除目录

- Delete: `modules/identity/rikki/`
- Delete: `modules/development/base/`
- Delete: `modules/gaming/base/`
- Delete: `modules/software/workstation/`
- Delete: `modules/business/common/`
- Delete: `modules/lifetime/common/`
- Delete: `modules/software/base-cli/`
- Delete: `modules/software/browser/`
- Delete: `modules/software/communication/`
- Delete: `modules/software/creative/`
- Delete: `modules/software/desktop-tools/`
- Delete: `modules/software/learning/`
- Delete: `modules/software/network-access/`
- Delete: `modules/software/remote-access/`
- Delete: `modules/software/reverse-engineering/`

### 目标新增叶子模块

- Create: `modules/development/toolchain/system/{meta.nix,module.nix}`
- Create: `modules/development/assistant/system/{meta.nix,module.nix}`
- Create: `modules/development/scripts/user/{meta.nix,module.nix}`
- Create: `modules/software/firefox/user/{meta.nix,module.nix}`
- Create: `modules/software/tor-browser/user/{meta.nix,module.nix}`
- Create: `modules/software/thunderbird/user/{meta.nix,module.nix}`
- Create: `modules/software/qq/user/{meta.nix,module.nix}`
- Create: `modules/software/feishu/user/{meta.nix,module.nix}`
- Create: `modules/software/signal-desktop/user/{meta.nix,module.nix}`
- Create: `modules/software/gimp/user/{meta.nix,module.nix}`
- Create: `modules/software/typst/user/{meta.nix,module.nix}`
- Create: `modules/software/kdenlive/user/{meta.nix,module.nix}`
- Create: `modules/software/typora/user/{meta.nix,module.nix}`
- Create: `modules/software/gnome-software/user/{meta.nix,module.nix}`
- Create: `modules/software/remmina/user/{meta.nix,module.nix}`
- Create: `modules/software/filezilla/user/{meta.nix,module.nix}`
- Create: `modules/software/anki/user/{meta.nix,module.nix}`
- Create: `modules/software/calibre/user/{meta.nix,module.nix}`
- Create: `modules/software/xray/user/{meta.nix,module.nix}`
- Create: `modules/software/sing-box/user/{meta.nix,module.nix}`
- Create: `modules/software/v2rayn/user/{meta.nix,module.nix}`
- Create: `modules/software/ghidra/user/{meta.nix,module.nix}`
- Create: `modules/software/gnucash/user/{meta.nix,module.nix}`
- Create: `modules/software/spotify/user/{meta.nix,module.nix}`
- Create: `modules/software/vscode/user/{meta.nix,module.nix}`
- Create: `modules/software/gemini-cli/user/{meta.nix,module.nix}`
- Create: `modules/software/treefmt/user/{meta.nix,module.nix}`
- Create: `modules/software/obs-studio/user/{meta.nix,module.nix}`
- Create: `modules/software/osu-lazer/user/{meta.nix,module.nix}`
- Create: `modules/software/hmcl/user/{meta.nix,module.nix}`
- Create: `modules/software/mindustry/user/{meta.nix,module.nix}`
- Create: `modules/software/ddnet/user/{meta.nix,module.nix}`

## Chunk 1: 框架先支持 `views/`

### Task 1: 扩展 `buildPlan` 数据模型

**Files:**
- Modify: `lib/capabilityGraph.nix`
- Modify: `parts/systems.nix`
- Test: `tests/view-graph.sh`

- [ ] **Step 1: 为宿主机 `meta.nix` 增加 `views` 字段解析**

在 `buildPlanFromMeta` 中：

- 读取宿主机 `views`
- 默认值为 `[]`
- 保持 `capabilities` 只表示叶子能力

- [ ] **Step 2: 为用户 `meta.nix` 增加 `views` 字段解析**

在 `normalizeUser` 中：

- 读取用户 `views`
- 默认值为 `[]`

- [ ] **Step 3: 新增视图加载函数**

在 `lib/capabilityGraph.nix` 中新增：

- `parseViewId`
- `viewDir`
- `loadViewFacet`
- `resolveViews`

要求：

- 校验 `support.platform`
- 校验 `support.arch`
- 支持 `includes`
- 支持循环检测

- [ ] **Step 4: 让 `buildPlanFromMeta` 先解析视图再解析 capability**

最终流程：

1. 解析 `views`
2. 得到展开后的叶子 `capabilities`
3. 与显式 `capabilities` 合并去重
4. 进入现有 capability 解析

- [ ] **Step 5: 把解析结果写入 `buildPlan`**

至少写入：

- `systemViews`
- `user.views`
- `systemCapabilities`
- `user.capabilities`

- [ ] **Step 6: 在 `parts/systems.nix` 传入 `viewsDir`**

- [ ] **Step 7: 新增失败测试**

Create: `tests/view-graph.sh`

覆盖：

- 未知视图
- 视图缺少 facet
- 视图循环
- 平台不支持
- 正常展开

- [ ] **Step 8: 运行测试确认失败**

Run: `./tests/view-graph.sh`
Expected: FAIL，因为 `views/` 尚未实现

## Chunk 2: 错误模型与文档同步

### Task 2: 增加 `view.*` 错误类型

**Files:**
- Modify: `lib/errors.nix`
- Test: `tests/view-graph.sh`

- [ ] **Step 1: 新增错误码**

至少包括：

- `view.invalidId`
- `view.unknown`
- `view.missingFacet`
- `view.unsupportedPlatform`
- `view.unsupportedArch`
- `view.cycle`
- `view.invalidField`

- [ ] **Step 2: 中英文错误文案补齐**

- [ ] **Step 3: 运行测试确认报错信息正确**

Run: `./tests/view-graph.sh`
Expected: FAIL with expected localized errors before full implementation, then PASS after implementation

### Task 3: 更新 README / AGENTS 的架构说明

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 文档中新增 `views/` 目录**

- [ ] **Step 2: 更新 `Capability Layout`**

明确：

- `modules/` 仅承载叶子能力
- `views/` 仅承载聚合视图

- [ ] **Step 3: 更新宿主机与用户 `meta.nix` 示例**

示例必须显式区分：

- `views = [ ... ]`
- `capabilities = [ ... ]`

## Chunk 3: 身份退出模块层

### Task 4: 将 `identity/rikki` 迁移到 `systems/shared/users/rikki/`

**Files:**
- Create: `systems/shared/users/rikki/default.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/default.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/default.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`
- Delete: `modules/identity/rikki/user/meta.nix`
- Delete: `modules/identity/rikki/user/module.nix`
- Delete: `modules/identity/rikki/`
- Test: `tests/identity-placement.sh`

- [ ] **Step 1: 在共享用户默认文件中实现 Git 身份**

`systems/shared/users/rikki/default.nix` 负责：

- `programs.git.enable`
- `programs.git.lfs.enable`
- `programs.git.settings.user.name`
- `programs.git.settings.user.email`
- `programs.git.settings.user.signingkey`
- `programs.git.settings.commit.gpgsign`

- [ ] **Step 2: 两台宿主机用户 `default.nix` 导入共享默认文件**

- [ ] **Step 3: 从两台宿主机用户 `meta.nix` 中移除 `identity/rikki`**

- [ ] **Step 4: 删除 `modules/identity/rikki`**

- [ ] **Step 5: 新增架构测试**

Create: `tests/identity-placement.sh`

断言：

- `modules/identity` 不再存在具体用户目录
- `systems/shared/users/rikki/default.nix` 存在

- [ ] **Step 6: 运行测试确认通过**

Run: `./tests/identity-placement.sh`
Expected: PASS

## Chunk 4: 把聚合模块迁移到 `views/`

### Task 5: 迁移 `development/base`

**Files:**
- Create: `views/development/base/system.nix`
- Create: `views/development/base/user.nix`
- Delete: `modules/development/base/system/meta.nix`
- Delete: `modules/development/base/system/module.nix`
- Delete: `modules/development/base/user/meta.nix`
- Delete: `modules/development/base/user/module.nix`
- Delete: `modules/development/base/user/scripts/traffic_calc.sh`
- Delete: `modules/development/base/user/scripts/workspace.sh`
- Delete: `modules/development/base/user/scripts/genprime.sh`
- Delete: `modules/development/base/user/scripts/gitsign.sh`
- Delete: `modules/development/base/`

- [ ] **Step 1: 先创建新的叶子模块**

先不要直接迁移视图，先创建：

- `modules/development/toolchain/system`
- `modules/development/assistant/system`
- `modules/development/scripts/user`
- `modules/software/vscode/user`
- `modules/software/gemini-cli/user`
- `modules/software/treefmt/user`

- [ ] **Step 2: 把旧 `development/base` 的内容迁入叶子**

- [ ] **Step 3: 创建 `views/development/base/system.nix`**

仅组合：

- `development/toolchain`
- `development/assistant`

如仍需要通用 CLI / 诊断工具，必须迁入其他叶子能力后再由视图引用，不能直接塞回视图。

- [ ] **Step 4: 创建 `views/development/base/user.nix`**

仅组合：

- `development/scripts`
- `software/vscode`
- `software/gemini-cli`
- `software/treefmt`

- [ ] **Step 5: 删除旧 `modules/development/base`**

### Task 6: 迁移 `gaming/base`

**Files:**
- Create: `views/gaming/base/system.nix`
- Create: `views/gaming/base/user.nix`
- Create: `modules/gaming/steam/system/{meta.nix,module.nix}`
- Create: `modules/gaming/performance/system/{meta.nix,module.nix}`
- Create: `modules/software/obs-studio/user/{meta.nix,module.nix}`
- Create: `modules/software/osu-lazer/user/{meta.nix,module.nix}`
- Create: `modules/software/hmcl/user/{meta.nix,module.nix}`
- Create: `modules/software/mindustry/user/{meta.nix,module.nix}`
- Create: `modules/software/ddnet/user/{meta.nix,module.nix}`
- Delete: `modules/gaming/base/system/meta.nix`
- Delete: `modules/gaming/base/system/module.nix`
- Delete: `modules/gaming/base/user/meta.nix`
- Delete: `modules/gaming/base/user/module.nix`
- Delete: `modules/gaming/base/`

- [ ] **Step 1: 系统侧拆叶子**

迁移：

- `steam` -> `modules/gaming/steam/system`
- `mangohud` / `gamemode` -> `modules/gaming/performance/system`

- [ ] **Step 2: 用户侧拆成应用叶子**

迁移：

- `obs-studio`
- `osu-lazer-bin`
- `hmcl`
- `mindustry`
- `ddnet`

- [ ] **Step 3: 由 `views/gaming/base/*` 重新组合**

- [ ] **Step 4: 删除旧 `modules/gaming/base`**

### Task 7: 迁移 `software/workstation`

**Files:**
- Create: `views/software/workstation/user.nix`
- Delete: `modules/software/workstation/user/meta.nix`
- Delete: `modules/software/workstation/user/module.nix`
- Delete: `modules/software/workstation/`

- [ ] **Step 1: 先完成应用叶子拆分**

工作站视图最终只组合应用叶子，不再引用中间分类模块。

- [ ] **Step 2: 创建 `views/software/workstation/user.nix`**

只组合真正的“默认桌面应用组合”，不再包含浏览器。

- [ ] **Step 3: 删除旧 `modules/software/workstation`**

## Chunk 5: 把弱语义软件分类模块改成应用叶子

### Task 8: 浏览器与通信应用

**Files:**
- Create: `modules/software/firefox/user/{meta.nix,module.nix}`
- Create: `modules/software/tor-browser/user/{meta.nix,module.nix}`
- Create: `modules/software/thunderbird/user/{meta.nix,module.nix}`
- Create: `modules/software/qq/user/{meta.nix,module.nix}`
- Create: `modules/software/feishu/user/{meta.nix,module.nix}`
- Create: `modules/software/signal-desktop/user/{meta.nix,module.nix}`
- Delete: `modules/software/browser/user/meta.nix`
- Delete: `modules/software/browser/user/module.nix`
- Delete: `modules/software/browser/`
- Delete: `modules/software/communication/user/meta.nix`
- Delete: `modules/software/communication/user/module.nix`
- Delete: `modules/software/communication/`

- [ ] **Step 1: 逐个写应用叶子**

- [ ] **Step 2: 在视图中引用新叶子**

- [ ] **Step 3: 删除旧分类模块**

### Task 9: 创作、远程与学习应用

**Files:**
- Create: `modules/software/gimp/user/{meta.nix,module.nix}`
- Create: `modules/software/typst/user/{meta.nix,module.nix}`
- Create: `modules/software/kdenlive/user/{meta.nix,module.nix}`
- Create: `modules/software/typora/user/{meta.nix,module.nix}`
- Create: `modules/software/gnome-software/user/{meta.nix,module.nix}`
- Create: `modules/software/remmina/user/{meta.nix,module.nix}`
- Create: `modules/software/filezilla/user/{meta.nix,module.nix}`
- Create: `modules/software/anki/user/{meta.nix,module.nix}`
- Create: `modules/software/calibre/user/{meta.nix,module.nix}`
- Delete: `modules/software/creative/user/meta.nix`
- Delete: `modules/software/creative/user/module.nix`
- Delete: `modules/software/creative/`
- Delete: `modules/software/desktop-tools/user/meta.nix`
- Delete: `modules/software/desktop-tools/user/module.nix`
- Delete: `modules/software/desktop-tools/`
- Delete: `modules/software/remote-access/user/meta.nix`
- Delete: `modules/software/remote-access/user/module.nix`
- Delete: `modules/software/remote-access/`
- Delete: `modules/software/learning/user/meta.nix`
- Delete: `modules/software/learning/user/module.nix`
- Delete: `modules/software/learning/`

- [ ] **Step 1: 逐个写应用叶子**

- [ ] **Step 2: 由视图重新组合**

- [ ] **Step 3: 删除旧分类模块**

### Task 10: 网络、逆向与一应用一模块迁移

**Files:**
- Create: `modules/software/xray/user/{meta.nix,module.nix}`
- Create: `modules/software/sing-box/user/{meta.nix,module.nix}`
- Create: `modules/software/v2rayn/user/{meta.nix,module.nix}`
- Create: `modules/software/ghidra/user/{meta.nix,module.nix}`
- Create: `modules/software/gnucash/user/{meta.nix,module.nix}`
- Create: `modules/software/spotify/user/{meta.nix,module.nix}`
- Delete: `modules/business/common/user/meta.nix`
- Delete: `modules/business/common/user/module.nix`
- Delete: `modules/business/common/`
- Delete: `modules/lifetime/common/user/meta.nix`
- Delete: `modules/lifetime/common/user/module.nix`
- Delete: `modules/lifetime/common/`
- Delete: `modules/software/base-cli/user/meta.nix`
- Delete: `modules/software/base-cli/user/module.nix`
- Delete: `modules/software/base-cli/`
- Delete: `modules/software/network-access/user/meta.nix`
- Delete: `modules/software/network-access/user/module.nix`
- Delete: `modules/software/network-access/`
- Delete: `modules/software/reverse-engineering/user/meta.nix`
- Delete: `modules/software/reverse-engineering/user/module.nix`
- Delete: `modules/software/reverse-engineering/`

- [ ] **Step 1: 把网络工具拆成具体应用叶子**

- [ ] **Step 2: 把 `gnucash`、`spotify` 从 `common` 迁到应用叶子**

- [ ] **Step 3: 把 `bc`、`jq`、`fastfetch` 迁入更合适的叶子或直接放回视图决策**

推荐：

- `bc`
- `jq`
- `fastfetch`

迁入 `modules/software/jq`、`modules/software/fastfetch` 等过于机械，因此这一批应优先放入 `views/software/workstation/user.nix` 的 `capabilities` 之外，由共享用户默认或 `development/scripts` 明确实现。实施前需再做一次裁剪审查，避免制造新的机械模块。

## Chunk 6: 宿主机与用户实例全面迁移

### Task 11: 迁移宿主机 `meta.nix` 到 `views + capabilities`

**Files:**
- Modify: `systems/laptop-asus-tx4-personal/meta.nix`
- Modify: `systems/laptop-mbpM2/meta.nix`

- [ ] **Step 1: 宿主机新增 `views = [ ... ]`**

Linux：

- `development/base`
- `gaming/base`

Darwin：

- `development/base`

- [ ] **Step 2: 宿主机 `capabilities = [ ... ]` 保留叶子能力**

- [ ] **Step 3: 从宿主机 capability 列表中移除所有聚合模块**

### Task 12: 迁移用户 `meta.nix` 到 `views + capabilities`

**Files:**
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`

- [ ] **Step 1: 用户新增 `views = [ ... ]`**

Linux：

- `development/base`
- `software/workstation`
- `gaming/base`

Darwin：

- `development/base`
- `software/workstation`

- [ ] **Step 2: 用户 `capabilities = [ ... ]` 只保留叶子**

- [ ] **Step 3: 显式处理 `laptop-mbpM2` 的 Firefox 约束**

Darwin 用户不选择：

- `software/firefox`

Linux 用户显式选择：

- `software/firefox`

- [ ] **Step 4: 继续保留或迁移 `vscode` 的宿主机级禁用策略**

若 `software/vscode` 仍使用 `enable` 选项，则把 override 路径改到新模块；否则直接不在 Darwin 用户 capability / view 中选择该叶子。

## Chunk 7: 测试与回归

### Task 13: 新增与更新测试

**Files:**
- Create: `tests/view-graph.sh`
- Create: `tests/identity-placement.sh`
- Create: `tests/module-leaf-audit.sh`
- Modify: `tests/software-capabilities.sh`
- Modify: `tests/migration-equivalence.sh`
- Modify: `tests/framework-smoke.sh`
- Modify: `tests/cleanup-check.sh`

- [ ] **Step 1: `tests/software-capabilities.sh` 改为验证叶子应用选择**

至少断言：

- Darwin 不包含 `firefox`
- Darwin 不再启用 `software/browser`
- Linux 明确包含 `software/firefox`
- Linux 与 Darwin 均通过视图得到其他工作站应用

- [ ] **Step 2: `tests/migration-equivalence.sh` 改为验证新数据模型**

断言：

- 宿主机与用户 `meta.nix` 都包含 `views`
- 旧 `identity/rikki`
- 旧 `business/common`
- 旧 `lifetime/common`
- 旧 `software/workstation`
- 旧 `development/base`
- 旧 `gaming/base`

不再作为 `modules/` 目标存在

- [ ] **Step 3: `tests/framework-smoke.sh` 增加对 `buildPlan.*Views` 的断言**

- [ ] **Step 4: `tests/module-leaf-audit.sh` 审计 `modules/`**

断言：

- `modules/` 下不再存在 `common`
- `modules/` 下不再存在 `base`
- `modules/identity/` 不再存在具体用户

- [ ] **Step 5: `tests/cleanup-check.sh` 补充空目录与遗留路径检查**

### Task 14: 运行完整验证

**Files:**
- Modify: None

- [ ] **Step 1: 运行新增测试**

Run: `./tests/view-graph.sh`
Expected: PASS

Run: `./tests/identity-placement.sh`
Expected: PASS

Run: `./tests/module-leaf-audit.sh`
Expected: PASS

- [ ] **Step 2: 运行现有回归**

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

## Chunk 8: 收尾与兼容层删除

### Task 15: 清理遗留目录与过渡文档

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/specs/2026-04-08-software-capability-refactor-design.md`
- Modify: `docs/superpowers/plans/2026-04-08-software-capability-refactor.md`
- Modify: `docs/superpowers/plans/2026-04-08-development-base-split.md`
- Modify: `docs/superpowers/plans/2026-04-08-capability-architecture-realignment.md`

- [ ] **Step 1: 在旧设计文档中标记 superseded**

- [ ] **Step 2: 移除旧路径引用**

- [ ] **Step 3: 删除空目录**

特别确认：

- `modules/business/`
- `modules/lifetime/`
- `modules/identity/`

- [ ] **Step 4: 清理无关格式化 diff**

最终提交前，压缩与本次架构迁移无关的纯格式化改动。

## 风险与控制

1. 不要把“分类模块”原样搬到 `views/`，否则只是换目录不换思路。
2. 不要为机械的单包命名引入过多毫无收益的叶子；像 `bc`、`jq`、`fastfetch` 这类需要二次裁剪，避免新一轮冗余。
3. 不要让 `views/` 重新长出实现逻辑；视图必须保持纯数据。
4. 不要把身份逻辑再包装成“共享 identity 模块”；共享身份只能发生在 `systems/` 层。
5. `laptop-mbpM2` 不要 `firefox` 必须通过“不选择叶子模块”表达，而不是通过浏览器聚合里的内部开关表达。
