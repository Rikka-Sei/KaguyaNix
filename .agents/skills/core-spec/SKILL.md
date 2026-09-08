---
name: core-spec
description: Use when 编写、审计或变更核心权威 spec（跨模块/跨进程契约、状态机、协议语义、长期唯一权威规格），或发现 spec 与代码契约漂移、验收屏障失败、决策无法归因需要收敛时
---

# Core Spec（核心权威规格）

## Overview

Core spec 是一份“开发照着做不出错、测试照着测不漏测、三个月后还能看懂”的唯一权威规格。本技能是一套模板加总约束：

- **模板**决定每个 spec 长什么样、tools 放哪里；
- **总约束**决定什么算写完、什么算通过；
- **验证脚本不是本技能的主体**，它们是每个 spec 自带的验收门，随 spec 一起维护。

**术语约定：** 本技能使用面向 spec 编程的标准术语：权威规格（authoritative spec）、单一事实源（single source of truth）、规格契约（spec contract）、验收屏障（barrier）。不使用“活文档”一词。

**一句话总约束：** spec 中每一句规范性条款，都必须能回答“谁、在什么条件下、看到什么结果”，并且有一条可执行的证据链（决策 ID → 契约/测试锚点 → 验证命令全绿）。

**本质定义（先于一切）：** spec 是**目标定义**，不是**现状快照**。spec 写"应该是什么"（目标行为），不写"现在代码是什么"。spec 领先于代码是 spec-first 变更的常态：先改 spec 定义目标，代码随后实现。

**「默认代码未跟上 spec」的适用范围：** 仅当目标行为条款本身未被推翻、只是代码尚未实现该目标。不适用于条款自相矛盾、身份分层错误、把目录/搬家/import 前缀等 How 写进行为 spec。那一类是 spec 假设被推翻，不是代码落后。

**自省（发现问题必须停手）：** spec-first 不是「条款永远正确、执行者不许质疑」。权威约束的是已确认的目标行为；它不授权把写错的条款执行到底。执行本技能任一流程（新建、变更、审计、迁移、对照代码实施）时，一旦发现必须停手的信号，**立即用中文告知用户，给出证据与可选调整，等待确认**。用户表态前：不得继续按该条款改代码，不得为了让 audit 变绿而把错误布局或错误身份写进更多文件，不得一条路走到黑。

spec 有两条腿，缺一不可：

- **领先腿（目标行为）**：接口签名、状态机、错误模型、进度/重试/取消语义——定义"应该是什么"，可以领先代码。
- **根植腿（代码事实引用）**：错误码映射表、常量数值、符号名、既有签名——引用"代码里真实存在的事实"，必须与代码一致，不得凭空定义。

## When to Use

符合任意一条即启用本技能：

- 要定义跨模块、跨进程、跨端的契约：接口签名、状态机、协议语义、错误模型；
- 规格将作为长期唯一权威，plan 和代码都以它为准；
- 写 implementation plan 之前发现没有权威 spec，或现有 spec 无法支撑实施；
- 审计、变更现有核心 spec；发现 spec 与代码漂移、验收屏障失败、决策无法归因。

不启用本技能（走普通设计文档/注释）：

- 一次性 bug 修复、单模块内部实现说明；
- 内容不产生跨实现方契约、不需要长期权威。

## 与 brainstorming

对齐默认走 superpowers:**brainstorming**（一问一答、方案 2–3、分段设计、yes 才继续）。本技能是规格落点，不是访谈。

- brainstorming 若要把设计写成文件：写 **本技能的** `docs/specs/<name>/spec.md`，不要写 `docs/superpowers/specs/YYYY-MM-DD-…-design.md`。用户对 spec 位置的偏好见仓库 AGENTS.md，覆盖 brainstorming 默认路径。
- 触及已有域契约 → 走下面「变更权威规格」，不要另开一份日期戳设计文档。
- `.agents/skills/grill-with-docs` 仅用户显式调用；烤完落规格仍走本技能。
- 下游只接 superpowers:**writing-plans**，禁止 SDD。

## 目录契约

每个 core spec 必须长这样：

docs/specs/<spec-name>/
├── spec.md                    # 唯一权威规格正文（authoritative spec）
├── tools/                     # 本 spec 自带的验证工具，从 templates/tools 复制
│   ├── audit_manifest.json    # 唯一事实源：术语、决策、契约、锚点、屏障
│   ├── audit_spec.py          # 结构审计器（五门硬检查）
│   ├── test_audit_spec.py     # 审计器负例自测（每类违规都要能失败）
│   ├── barriers.py            # 验收屏障运行器（有代码后必须全绿）
│   └── README.md              # 本 spec 验证命令与状态说明
├── issues/                    # 问题/风险登记（调查记录，非规范性正文）；一个问题一个文件，命名 YYYY-MM-DD-<中文短slug>.md
│   └── README.md              # 本目录规则、文件骨架与状态总览，从 templates/issues 复制
└── history/                   # 日期戳冻结快照，只读不更新
    └── README.md
```

硬性规则：

1. 验证脚本**只允许**放在 `docs/specs/<spec-name>/tools/`，与 spec 同目录、随 spec 提交；不得散落在全局 `tools/`。
2. 每个 spec 的 tools 是**自包含副本**，从本技能模板复制后独立演化；修改通用规则要先改本技能的模板，再逐 spec 迁移。
3. `spec.md` 是唯一权威；`history/` 只放冻结快照，任何人在快照上做“补丁式修订”都算治理违规。
4. `issues/` 只放问题/风险调查记录，不放规范性条款；一个问题一个文件，命名 `YYYY-MM-DD-<中文短slug>.md`，骨架见 `templates/issues/README.md`。
5. issue 状态原地流转：`open` → `resolved`/`wontfix`；`resolved`/`wontfix` 必须填写 §9 决策 ID；不迁入 `history/`。

## 自省：必须停手告知用户的信号

非穷举。命中任一条即停，先商量，再决定改 spec 还是改代码。

- 条款把不同身份的对象放在同一层（例如面板聚合与设备发包共用一个目录身份）。
- 行为 spec 写入纯 How：目录分组、import 前缀、搬家名单；而同一份 spec 的行为条款已经否定该分组。
- 新证据推翻 §9 某条决策的假设（身份、边界、谁对谁做什么），与「代码还没实现目标」不是同一类。
- 继续做下去只会扩大错误面（manifest 把错误路径锁死、plan 按错误决策 ID 全仓替换）。

告知时必须有：发现了什么、证据在哪（spec 行号 / 决策 ID / 与另一条款的矛盾）、建议怎么调（改 spec / 缩小条款 / 不改）。禁止自行选定后继续实施。

用户确认改 spec 后：先归因新决策 ID，或把被推翻的条款原地合并/删除，再改正文与 manifest。这仍是 spec-first，只是先承认假设错了。

## Spec 正文边界

spec 正文必须写：背景/目标/非目标、术语表、系统模型与状态机、功能需求与接口契约、错误模型、NFR、异常与边界、验收标准、决策日志、验证入口。

spec 正文不得写：实施波次（W0–W8 等）、S0–S5 迁移推进、具体迁移步骤、锁算法与实现级设计细节、问题调查过程与未闭环风险。这些内容写入 `plans/`、独立设计文档或 `issues/`；spec 只保留决策 ID 归因、可验证契约摘要与指针。

调查中尚未通过 §9 决策日志闭环的问题与风险记录在 `issues/`；正文只保留由决策 ID 归因的结论。

例外：当某实现约束本身构成跨层公开契约（如锁序、发送语义）时，只保留可验证的一句话契约，不写推导过程与历史推进。

## Workflow

### 1. 新建 core spec

1. 先做 scope check：符合 When to Use 判据才继续，否则退化为普通设计文档。
2. 创建 `docs/specs/<name>/`，把本技能 `templates/` 下全部文件复制到对应位置；新建 spec 必须使用模板工具，不允许另起一套全局脚本。
3. **先写 manifest**：术语白/黑名单、决策 ID 范围、代码契约 pattern、测试锚点、屏障命令。manifest 是唯一事实源，先于正文写。
4. 按 `templates/spec.md` 的骨架逐节写正文；每写一节，对照 `reference/quality-gates.md` 自检 G1–G3。
5. 状态为 `draft` 时允许测试锚点/屏障尚未落地；切到 `authoritative` 前，锚点必须真实存在且 `barriers.py` 全绿。
6. 跑 `python tools/test_audit_spec.py` 与 `python tools/audit_spec.py`，必须 PASS。
7. 交付实施时使用 superpowers:writing-plans，plan 头部的 `Spec:` 必须写清 spec 路径；提交说明与签名遵循仓库 AGENTS.md 约定。

### 2. 变更权威规格（spec-first 变更）

1. 任何行为变更，先在 §决策日志新增决策 ID 或归因已有 ID，再改正文。
2. 被取代条款**原地合并或删除**，禁止“（已被 Dxx 取代）”之类的补丁标记。
3. 同步 `tools/audit_manifest.json`（term、锚点、契约、决策范围）；**移动或删除章节时必须同步修正所有引用该章节的 occurrence/scoped 规则**，审计器不得保留悬空规则。
4. 依次跑 `test_audit_spec.py`、`audit_spec.py`、`barriers.py`。spec 领先代码时（行为变更先改 spec、代码尚未实现）：`spec_status` 保持 `draft`，`code_contracts`/`test_anchors` 指向目标实现、暂未命中时审计降级为 warning，不阻断；代码实现落地、契约/锚点/屏障真实命中且 `barriers.py` 全绿后，再与代码同批提交并切 `authoritative`。
5. plan 与 spec 冲突时，**未推翻的目标行为**以 spec 为准，改 plan。若执行中发现 spec 假设不成立（见「自省」），停手告知用户，不得为迁就条款而改 plan/代码一条路走到黑；用户确认后再归因决策 ID 并改 spec。

### 3. 审计 core spec

审计结论必须是**可复现证据 + 分级问题清单**，不是一句“审计器 PASS”：

- 以 `reference/quality-gates.md` 五门为框架逐项打分；
- 对每条 P0/P1 问题给出 spec 行号、代码/测试证据、修复动作；
- 审计结束时必须实际运行 `audit_spec.py`、`test_audit_spec.py`、`barriers.py`，把真实输出写进结论。
- 审计器 PASS 不能覆盖身份/分层/What-How 混写。发现这类问题按「自省」告知用户，不要输出「照条款改代码」当作唯一整改。

### 4. 存量 spec 迁移

存量权威 spec 迁入 core-spec 布局时：

1. 先保留正文既有章节编号与交叉引用，不要为套模板做大规模重排；把迁移前版本冻结到 `history/YYYY-MM-DD-<标题>.md`。
2. 把实施波次、迁移步骤与设计推进内容移入 `plans/` 或 roadmap，正文只留规范性摘要与指针。
3. **保留已通过验证的既有工具**，将其迁入 spec 自带 `tools/` 并改为 canonical 文件名（audit_spec.py / audit_manifest.json / barriers.py 等）；只适配路径常量，不得为了统一把成熟工具替换成模板实现。
4. 同步 `audit_manifest.json`：移动章节后，相关 occurrence/scoped 规则要么指向新章节，要么收缩为对正文摘要/决策记录的检查。
5. 更新仓库内引用（AGENTS.md、发布文档、未冻结的 active plan）；`history/` 与历史 plans 中的旧路径不改写。
6. 新位置全套验证 PASS 后，才删除旧全局脚本；spec、tools 与代码同批提交。

### 5. 记录与关闭 issue

1. 发现 spec 与代码/线上行为不一致、或风险待确认且暂不改行为时，在 `issues/` 按 `issues/README.md` 骨架登记，状态 `open`。
2. §9 决策日志新增或归因决策 ID 并落地后，原地将 issue 改为 `resolved` 或 `wontfix`，填写关联决策 ID；不迁入 `history/`。
3. 变更或审计前先打开 `issues/`，确认 open 项是否影响本次变更；有影响的必须先完成 §9 决策归因，再进入 plan/代码。

## Hard Gates（不满足即失败）

| 门 | 判据（摘要） |
|---|---|
| G1 精确与可追溯 | 无模糊词；每条需求有唯一 REQ ID、优先级、Given/When/Then |
| G2 异常与 NFR 完整 | 状态机覆盖失败分支；NFR 全部量化；错误模型完整 |
| G3 内部一致 | 一个术语一个定义；被取代条款已合并/删除；图、表、验收不互相矛盾；正文无实施波次标识与实现级设计 |
| G4 验证实测全绿 | 审计器、负例自测、屏障命令实际运行并通过；测试锚点真实存在 |
| G5 治理与元信息 | 每条规范可归因决策 ID；版本/受众/范围/术语表/Out of Scope 完整 |

完整检查表见 `reference/quality-gates.md`。任何一门不满足，spec 都不得标记为 authoritative。

## Common Mistakes

| 错误 | 后果 | 正确做法 |
|---|---|---|
| 审计器 PASS 就宣布 spec 正确 | 词法检查发现不了语义矛盾和契约漂移 | G3 自检 + 逐条契约对照代码 + 屏障实跑 |
| 保留旧条款并标注“已取代” | 一份文档两套语义 | 原地合并或删除，历史交给 git 和 history/ |
| 只改一处，不同步目标/状态表/验收 | 开发按旧语义实现 | 变更时全文检索相关章节一并收敛 |
| spec 里写测试锚点但不跑 | 锚点可能根本不存在 | 锚点列入 manifest，audit 校验存在性，barriers 实跑 |
| 把锁算法、实施波次写进 spec 主体 | 文档臃肿、What/How 不分 | 下沉到设计文档/plan；spec 只保留契约性约束 |
| 迁移时把成熟验证工具替换成模板 | 丢失已固化的规则与负例 | 存量迁移保留既有工具，只改 canonical 文件名与路径 |
| 移动章节后不更新 manifest | 审计规则悬空或错指章节 | 同步修正 occurrence/scoped 的 sections 与 count |
| 把问题调查过程直接写进 spec 正文 | 正文混入非规范性内容，行为无法判定 | 调查记录进 `issues/`，正文只保留决策 ID 归因结论 |
| spec 写成现状快照（记录当前代码行为） | 目标行为被现状锁死，无法驱动变更 | spec 定义目标，代码实现目标；现状与目标不一致是待变更信号，不是 spec 写错 |
| spec 凭空定义代码事实（错误码/常量/签名） | 契约与代码漂移，屏障形同虚设 | 代码事实引用必须 grep 到代码，列入 manifest code_contracts |
| 发现 spec 写错仍按条款把代码/manifest 改到位 | 错误假设被 audit 锁死，越做越难撤 | 停手告知用户，商量改 spec；确认前不扩大改动面 |
| 把「spec 是权威」读成「出错的 spec 不准改」 | 执行者不敢质疑，一条路走到黑 | 权威只约束已确认的目标行为；假设被推翻就改 spec |

## Red Flags — STOP and fix

- 看到“可能 / 大概 / 尽量 / 友好 / 快速”等词出现在规范性条款里
- “（已被 Dxx 取代）”“本次暂不处理”出现在权威规格正文
- `grep` 不到 spec 引用的测试名
- 变更没有归因决策 ID 就想改代码
- `W0–W8`、`S0–S5` 或“第 N 波次实施”出现在权威规格正文
- spec 正文出现"当前实现是 X""现有代码为 X"等现状描述，而非目标定义
- 拿错误条款压过身份/分层判断，不告知用户就继续实施
- 为了 audit 变绿，把已知错误的目录/身份写进更多契约

以上任何一条出现：先停、先告知用户。确认修 spec 则先修 spec 再继续；确认不改则记录 issue，不得假装条款有效并继续铺开。

## 相关技能

- 对齐：superpowers:brainstorming（默认）；`.agents/skills/grill-with-docs` 仅用户显式调用
- 写实施计划：superpowers:writing-plans
- 测试驱动开发：superpowers:test-driven-development
- 本技能模板与检查表：`templates/`、`reference/quality-gates.md`
