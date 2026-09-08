# 用户 homeDirectory 显式 null 穿透与 REQ-009 类型契约不符 — Issue

**状态:** open
**发现日期:** 2026-09-08
**最后更新:** 2026-09-08
**来源:** 代码审计（core-spec 修正后独立复审，P3）
**关联章节:** §4（REQ-009）、§3.2
**关联决策 ID:** 未归因

## 1. 现象

用户实例显式声明 `homeDirectory = null` 时，`null` 被静默接受并冻结进 buildPlan，最终在阶段二以与该字段无关的模块系统错误失败，而非按 REQ-009 契约抛 `node.invalidType`。

## 2. 证据链

| 证据 | 位置 |
|---|---|
| `ensureOptionalString` 允许 `null \| string` 通过 | lib/capGraph.nix:68-78 |
| `homeDirectory` 规范化经 `ensureOptionalString`，缺省表达式为 `attrs.homeDirectory or <平台推导>`——`or` 仅在属性缺失时触发，属性存在且值为 `null` 时不触发 | lib/capGraph.nix:397-404 |
| 阶段二直接消费 `home.homeDirectory = userCfg.homeDirectory` | parts/systems.nix（mkUserModule） |
| spec 目标契约：`homeDirectory`（string，缺省按平台推导） | docs/specs/kaguya/spec.md REQ-009、§3.2 |

## 3. 根因

已确认：`ensureOptionalString` 的"可选"语义与 `or` 缺省机制组合后，"显式 null"落入既非缺省推导、又非类型拒绝的缝隙。`ensureOptionalString` 当前仅被 homeDirectory 一处使用。

## 4. 影响

仅影响显式声明 `homeDirectory = null` 的病态输入：错误从阶段一可定位的 `node.invalidType` 退化为阶段二模块系统对 `home.homeDirectory` 的报错。正常声明（缺省、合法字符串）不受影响；spec 的目标行为条款未被推翻。

## 5. 建议

- 代码层二选一：(a) `homeDirectory` 改用 `ensureString`，显式 null 抛 `node.invalidType`；(b) 将显式 null 视同未声明，走平台推导（`attrs.homeDirectory != null` 判断）。
- spec 层：两案均在 REQ-009 目标契约之内，无需修改正文；落地时在 §9 归因新决策 ID 并闭环本 issue。

## 6. 闭环记录

- open：等待二选一决策；无阻塞中的框架变更依赖本项。
