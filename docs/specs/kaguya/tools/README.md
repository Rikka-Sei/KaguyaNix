# tools/ 说明

本目录是当前 core spec 自带的验证工具，从 `.agents/skills/core-spec/templates/tools/` 复制而来，**随 spec 独立维护，不与其他 spec 共享**。

| 文件 | 作用 | 何时必须 PASS |
|---|---|---|
| `audit_manifest.json` | 唯一事实源：术语、决策、代码契约、测试锚点、屏障命令 | 每次修改 spec 后同步更新 |
| `audit_spec.py` | 结构审计器（G1/G3/G4/G5 的机器可验证部分） | 每次修改 spec 后 |
| `test_audit_spec.py` | 审计器负例自测，保证审计器自己会失败 | 每次修改审计器规则后 |
| `barriers.py` | 验收屏障运行器 | spec 为 authoritative 时必须全绿 |

## 标准验证顺序

```bash
python tools/test_audit_spec.py   # 先证明审计器可信
python tools/audit_spec.py        # 再审计 spec
python tools/barriers.py          # 最后跑验收屏障（draft 可为空）
```

## 状态约定

- `audit_manifest.json` 的 `spec_status` 为 `draft` 时：允许代码/测试锚点尚未落地，缺失锚点只告警。
- 切到 `authoritative` 前必须：锚点真实存在、契约 pattern 与代码一致、旧契约零命中、`barriers.py` 全绿。
- 三者任一失败，本 spec 不得宣称 authoritative。

## 变更规则

1. 任何行为变更：先改 `spec.md` 的决策日志，再改正文，然后同步本目录 manifest。
2. 禁止先改代码再补 spec；spec 与代码必须同批提交。
3. 增加审计规则时必须同时给 `test_audit_spec.py` 增加对应负例。

## 本 spec 状态（2026-09-08）

- `spec_status = authoritative`：代码契约全部命中、旧契约零命中、12 个验收屏障实跑全绿（`tests/framework-smoke.sh`、`tests/error-paths.sh` 等，合计 12/12 PASS）。
- 本仓库测试为 bash 脚本、无 Python 测试函数，故 manifest `test_anchors` 为空集；bash 断言以 `code_contracts`（`tests/*.sh`）与 `barriers` 接入。
- 已知未闭环问题见 `../issues/`：`2026-09-08-未接线错误码.md`（保留错误码 `user.invalidShell` / `view.invalidField`）、`2026-09-08-homeDirectory-null穿透.md`（显式 null 穿透，REQ-009 目标契约之内）。
