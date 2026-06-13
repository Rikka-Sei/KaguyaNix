# Software Capability Refactor Implementation Plan

> **SUPERSEDED**：由 docs/superpowers/specs/2026-06-11-cap-view-architecture-design.md 及其计划 2026-06-11-cap-view-architecture.md 取代。

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `software/common` 重构为语义明确的软件 capability 组合，并补全 README 中各类 `meta.nix` 字段说明。

**Architecture:** 通过“叶子 capability + 聚合 capability”两层组织替代原有 `software/common` 大包。测试先表达新的 capability 结构与包归属，再最小化修改模块、宿主机元数据和文档，使 capability 图、宿主机实例与 README 保持一致。

**Tech Stack:** Nix, Home Manager, nix-darwin, NixOS, Bash 测试脚本

---

## Chunk 1: 测试先行

### Task 1: 更新软件 capability 测试预期

**Files:**
- Modify: `tests/software-capabilities.sh`
- Modify: `tests/migration-equivalence.sh`

- [ ] **Step 1: 写出新的测试预期**

将测试改为断言：
- Linux 用户 capability 列表包含 `software/workstation`、`software/network-access`、`software/learning`、`software/logseq`、`software/reverse-engineering`
- Linux 用户 capability 列表不再包含 `software/common`
- Darwin 用户 capability 列表包含 `software/workstation`、`software/network-access`
- Darwin 用户 capability 列表不包含 `software/common`、`software/logseq`
- Linux 软件包结果继续包含 `mindustry` 与 `ddnet`，但来源将由 `gaming/base` 提供

- [ ] **Step 2: 运行测试确认失败**

Run: `./tests/software-capabilities.sh`
Expected: FAIL，因为当前实现仍依赖 `software/common`

- [ ] **Step 3: 运行迁移测试确认失败**

Run: `./tests/migration-equivalence.sh`
Expected: FAIL，因为当前宿主机用户 `meta.nix` 尚未切换到新的 capability 集合

## Chunk 2: 拆分 capability

### Task 2: 新建软件叶子 capability 与聚合 capability

**Files:**
- Create: `modules/software/base-cli/user/meta.nix`
- Create: `modules/software/base-cli/user/module.nix`
- Create: `modules/software/browser/user/meta.nix`
- Create: `modules/software/browser/user/module.nix`
- Create: `modules/software/communication/user/meta.nix`
- Create: `modules/software/communication/user/module.nix`
- Create: `modules/software/creative/user/meta.nix`
- Create: `modules/software/creative/user/module.nix`
- Create: `modules/software/desktop-tools/user/meta.nix`
- Create: `modules/software/desktop-tools/user/module.nix`
- Create: `modules/software/remote-access/user/meta.nix`
- Create: `modules/software/remote-access/user/module.nix`
- Create: `modules/software/network-access/user/meta.nix`
- Create: `modules/software/network-access/user/module.nix`
- Create: `modules/software/learning/user/meta.nix`
- Create: `modules/software/learning/user/module.nix`
- Create: `modules/software/reverse-engineering/user/meta.nix`
- Create: `modules/software/reverse-engineering/user/module.nix`
- Create: `modules/software/workstation/user/meta.nix`
- Create: `modules/software/workstation/user/module.nix`
- Delete: `modules/software/common/user/meta.nix`
- Delete: `modules/software/common/user/module.nix`

- [ ] **Step 1: 实现叶子 capability 的 `meta.nix`**

每个新 capability 都声明：
- 正确的 `optionPath`
- `linux` / `darwin` 与 `x86_64` / `aarch64` 支持表
- 需要时使用 `requires`
- 默认空 `conflicts`

- [ ] **Step 2: 实现叶子 capability 的 `module.nix`**

按设计文档填写最小包集，平台差异只留在叶子 capability 内部。

- [ ] **Step 3: 实现聚合 capability**

`software/workstation` 不直接声明包，只通过 `requires` 依赖：
- `software/base-cli`
- `software/browser`
- `software/communication`
- `software/creative`
- `software/desktop-tools`
- `software/remote-access`

- [ ] **Step 4: 运行软件 capability 测试**

Run: `./tests/software-capabilities.sh`
Expected: PASS

### Task 3: 回收游戏相关包并更新宿主机 capability

**Files:**
- Modify: `modules/gaming/base/user/module.nix`
- Modify: `systems/laptop-asus-tx4-personal/users/rikki/meta.nix`
- Modify: `systems/laptop-mbpM2/users/rikki/meta.nix`

- [ ] **Step 1: 将 `hmcl` `mindustry` `ddnet` 移入 `gaming/base`**

- [ ] **Step 2: 更新 Linux 宿主机用户 capability 列表**

切换为新的软件能力集合，并保留 `software/logseq`

- [ ] **Step 3: 更新 Darwin 宿主机用户 capability 列表**

切换为新的软件能力集合，不引入 Linux 专项能力

- [ ] **Step 4: 运行迁移与框架测试**

Run: `./tests/migration-equivalence.sh`
Expected: PASS

Run: `./tests/framework-smoke.sh`
Expected: PASS

## Chunk 3: README 字段说明补齐

### Task 4: 补全文档中的 `meta.nix` 字段职责

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 补充宿主机 `meta.nix` 字段说明**

- [ ] **Step 2: 补充用户 `meta.nix` 字段说明**

- [ ] **Step 3: 补充 capability facet `meta.nix` 字段说明**

- [ ] **Step 4: 将示例中的 `software/common` 更新为新能力**

- [ ] **Step 5: 运行文本与结构相关验证**

Run: `./tests/host-user-layout.sh`
Expected: PASS

## Chunk 4: 全量验证

### Task 5: 执行完整回归检查

**Files:**
- Modify: None

- [ ] **Step 1: 运行剩余测试**

Run: `./tests/cleanup-check.sh`
Expected: PASS

Run: `./tests/makefile-smoke.sh`
Expected: PASS

Run: `./tests/deploy-smoke.sh`
Expected: PASS

Run: `./tests/darwin-etc-compat.sh`
Expected: PASS

- [ ] **Step 2: 汇总结果与风险**

记录：
- 已新增的 capability
- 已删除的 capability
- README 新增的字段说明
- 仍未建模的潜在后续改进项
