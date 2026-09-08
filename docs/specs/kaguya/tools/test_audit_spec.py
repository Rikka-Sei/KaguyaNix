#!/usr/bin/env python3
"""core-spec 审计器负例自测模板。

用法：python test_audit_spec.py

用临时 fixture 验证 audit_spec.py 对每一类违规都会失败（G4 的“审计器自身
可信”部分）。新增检查规则时，必须同步在本文件新增一个负例。
"""
from __future__ import annotations

import contextlib
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
AUDIT = HERE / "audit_spec.py"

VALID_SPEC = """# 示例系统 — 权威规格（Spec）

**状态:** Draft
**版本:** 0.1
**受众:** 开发
**范围:** 测试
**治理:** 变更先改决策日志
**变更历史:** 见 history/

## 1. 背景与目标
spec 是唯一权威。

## 2. 术语表
| 术语 | 定义 |
|---|---|
| spec | 权威规格 |

## 3. 系统模型与状态机
状态机文本。

## 4. 功能需求与接口契约
- REQ-001 示例需求。

## 5. 错误模型
错误表。

## 6. 非功能需求（NFR）
性能数据。

## 7. 异常与边界条件
异常表。

## 8. 验收标准
AC-001 验收。

## 9. 决策日志
| D01 | 示例决策 | 1 | spec 出现 |
| 已确认决策 | 主要影响章节 | 验证规则 |

## 10. 验证
python tools/audit_spec.py
"""


def _base_manifest() -> dict:
    return {
        "spec_file": "spec.md",
        "spec_status": "draft",
        "repo_root": ".",
        "required_sections": [
            "1. 背景与目标", "2. 术语表", "3. 系统模型与状态机",
            "4. 功能需求与接口契约", "5. 错误模型", "6. 非功能需求（NFR）",
            "7. 异常与边界条件", "8. 验收标准", "9. 决策日志", "10. 验证",
        ],
        "metadata_terms": ["状态:", "版本:", "受众:", "范围:", "治理:", "变更历史:"],
        "vague_terms": ["可能", "大概", "尽量", "友好", "快速"],
        "forbidden_patterns": ["（已被\\s*D\\d+\\s*取代）", "补丁标记"],
        "requirement_prefix": "REQ-",
        "min_requirements": 1,
        "decision_prefix": "D",
        "latest_decision": 1,
        "decisions": [{
            "decision_id": "D01",
            "required_terms": ["spec"],
            "obsolete_terms": [],
            "scoped_terms": [],
            "whitelist": [],
            "required_occurrences": [
                {"pattern": "spec", "count": {"min": 1}, "sections": ["1"],
                 "reason": "spec 术语必须在背景章节出现"}],
            "forbidden_occurrences": [],
        }],
        "code_contracts": [],
        "obsolete_code_contracts": [],
        "test_anchors": [],
        "barriers": [],
    }


def _write_fixture(tmp: pathlib.Path, spec_text: str, manifest: dict,
                   files: dict[str, str] | None = None) -> pathlib.Path:
    (tmp / "spec.md").write_text(spec_text, encoding="utf-8")
    manifest_path = tmp / "audit_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2),
                             encoding="utf-8")
    for relative, content in (files or {}).items():
        path = tmp / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    return manifest_path


def _run(tmp: pathlib.Path, manifest_path: pathlib.Path) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(AUDIT), str(manifest_path)],
                          cwd=tmp, capture_output=True, text=True, check=False)


class AuditTemplateSelfTest(unittest.TestCase):
    @contextlib.contextmanager
    def _fixture(self, *, spec_text: str = VALID_SPEC, manifest=None,
                 files=None):
        tmpdir = tempfile.TemporaryDirectory()
        try:
            tmp = pathlib.Path(tmpdir.name)
            manifest = manifest if manifest is not None else _base_manifest()
            manifest_path = _write_fixture(tmp, spec_text, manifest, files)
            yield tmpdir, tmp, manifest_path
        finally:
            tmpdir.cleanup()

    def test_valid_spec_passes(self):
        with self._fixture() as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_missing_section_fails(self):
        spec = VALID_SPEC.replace("## 5. 错误模型", "")
        with self._fixture(spec_text=spec) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_vague_term_fails(self):
        spec = VALID_SPEC.replace("状态机文本。", "状态机可能快速切换。")
        with self._fixture(spec_text=spec) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_patch_marker_fails(self):
        spec = VALID_SPEC.replace("| D01 | 示例决策 | 1 | spec 出现 |",
                                  "| D01 | 示例决策（已被 D99 取代） | 1 | spec 出现 |")
        with self._fixture(spec_text=spec) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_duplicate_requirement_definition_fails(self):
        spec = VALID_SPEC.replace("- REQ-001 示例需求。", "- REQ-001 A。\n- REQ-001 B。")
        with self._fixture(spec_text=spec) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_reference_to_defined_requirement_passes(self):
        spec = VALID_SPEC.replace("AC-001 验收。", "AC-001 验收，参见 REQ-001。")
        with self._fixture(spec_text=spec) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_reference_to_undefined_requirement_fails(self):
        spec = VALID_SPEC.replace("AC-001 验收。", "AC-001 验收，参见 REQ-002。")
        with self._fixture(spec_text=spec) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_obsolete_term_in_spec_fails(self):
        manifest = _base_manifest()
        manifest["decisions"][0]["obsolete_terms"] = ["LegacyName"]
        spec = VALID_SPEC.replace("状态机文本。", "LegacyName 状态机文本。")
        with self._fixture(spec_text=spec, manifest=manifest) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_stale_decision_range_fails(self):
        spec = VALID_SPEC.replace("| D01 | 示例决策 |", "| D01–D24 覆盖声明 |")
        with self._fixture(spec_text=spec) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_authoritative_missing_anchor_fails(self):
        manifest = _base_manifest()
        manifest["spec_status"] = "authoritative"
        manifest["test_anchors"] = [{
            "name": "TestContractAnchor",
            "source_globs": ["src/**/*_test.go"],
            "required": True,
        }]
        with self._fixture(manifest=manifest) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_code_contract_drift_fails(self):
        manifest = _base_manifest()
        manifest["spec_status"] = "authoritative"
        manifest["code_contracts"] = [{
            "id": "tracker-signature",
            "pattern": r"func \(t \*Tracker\) MarkIdentityBound",
            "count": 1,
            "source_globs": ["src/**/*.go"],
            "reason": "权威契约必须与代码一致",
        }]
        manifest["obsolete_code_contracts"] = [{
            "pattern": r"MarkIdentityResolved",
            "source_globs": ["src/**/*.go"],
        }]
        files = {"src/tracker.go": "func (t *Tracker) MarkIdentityResolved() {}\n"}
        with self._fixture(manifest=manifest, files=files) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertNotEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_draft_code_contract_drift_is_warning(self):
        manifest = _base_manifest()
        manifest["code_contracts"] = [{
            "pattern": r"func \(t \*Tracker\) MarkIdentityBound",
            "count": 1,
            "source_globs": ["src/**/*.go"],
        }]
        manifest["obsolete_code_contracts"] = [{
            "pattern": r"MarkIdentityResolved",
            "source_globs": ["src/**/*.go"],
        }]
        files = {"src/tracker.go": "func (t *Tracker) MarkIdentityResolved() {}\n"}
        with self._fixture(manifest=manifest, files=files) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_code_contract_match_passes(self):
        manifest = _base_manifest()
        manifest["code_contracts"] = [{
            "id": "tracker-signature",
            "pattern": r"func \(t \*Tracker\) MarkIdentityBound",
            "count": 1,
            "source_globs": ["src/**/*.go"],
            "reason": "权威契约必须与代码一致",
        }]
        files = {"src/tracker.go": "func (t *Tracker) MarkIdentityBound() {}\n"}
        with self._fixture(manifest=manifest, files=files) as (_, tmp, manifest_path):
            completed = _run(tmp, manifest_path)
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
