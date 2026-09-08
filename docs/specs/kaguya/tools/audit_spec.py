#!/usr/bin/env python3
"""core-spec 通用结构审计器模板。

用法：python audit_spec.py [path/to/audit_manifest.json]
默认读取本脚本同目录的 audit_manifest.json。

本模板实现五门硬检查中的结构检查（G1/G3/G4/G5 的机器可验证部分）：
  - manifest schema 完整性
  - 必需章节、元信息、模糊词、补丁标记
  - REQ ID 唯一性
  - 决策 ID 范围新鲜度与 term 出现约束
  - 代码契约 pattern 与旧契约零命中
  - 测试锚点真实存在（authoritative 状态强制，draft 状态仅告警）

G2（异常/NFR 完整性）与 G3 的语义一致性由 reference/quality-gates.md 人工检查，
本脚本不假装能证明语义正确。
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

DEFAULT_MANIFEST = "audit_manifest.json"

_ID_BOUNDARY_L = r"(?<![A-Za-z0-9_])"
_ID_BOUNDARY_R = r"(?![A-Za-z0-9_])"


def _count_errors(count: object) -> list[str]:
    """校验 count 规格：正整数或含 min/max 的对象。"""
    if isinstance(count, bool):
        return ["count 必须是正整数或包含 min/max 的对象"]
    if isinstance(count, int):
        if count < 1:
            return ["count 必须是正整数或包含 min/max 的对象"]
        return []
    if isinstance(count, dict):
        extra = sorted(set(count) - {"min", "max"})
        if extra:
            return [f"count 对象含未知字段: {', '.join(extra)}"]
        if not count:
            return ["count 对象不能为空"]
        errors: list[str] = []
        for name in ("min", "max"):
            value = count.get(name)
            if value is None:
                continue
            if isinstance(value, bool) or not isinstance(value, int) or value < 0:
                errors.append(f"count {name} 必须是非负整数")
        if not errors and count.get("min") is not None and count.get("max") is not None \
                and count["min"] > count["max"]:
            errors.append("count min 不得大于 max")
        return errors
    return ["count 必须是正整数或包含 min/max 的对象"]


def _sections_errors(label: str, sections: object) -> list[str]:
    if not isinstance(sections, list) or not sections:
        return [f"{label} 必须是非空 list"]
    errors = []
    for section in sections:
        if not isinstance(section, str) or not re.fullmatch(r"\*|[1-9][0-9]*", section):
            errors.append(f"{label} 元素必须是章节号或 '*'")
            break
    return errors


def _validate_manifest(manifest: dict) -> list[str]:
    errors: list[str] = []
    required_keys = {
        "spec_file": str,
        "spec_status": str,
        "repo_root": str,
        "required_sections": list,
        "metadata_terms": list,
        "vague_terms": list,
        "forbidden_patterns": list,
        "requirement_prefix": str,
        "min_requirements": int,
        "decision_prefix": str,
        "latest_decision": int,
        "decisions": list,
        "code_contracts": list,
        "obsolete_code_contracts": list,
        "test_anchors": list,
        "barriers": list,
    }
    for key, expected_type in required_keys.items():
        if key not in manifest:
            errors.append(f"manifest 缺少必需键: {key}")
        elif not isinstance(manifest[key], expected_type):
            errors.append(f"manifest 键 {key} 类型错误，需要 {expected_type.__name__}")
    if manifest.get("spec_status") not in ("draft", "authoritative"):
        errors.append("spec_status 必须是 draft 或 authoritative")
    if isinstance(manifest.get("latest_decision"), int) and manifest["latest_decision"] < 1:
        errors.append("latest_decision 必须是正整数")
    if isinstance(manifest.get("min_requirements"), int) and manifest["min_requirements"] < 0:
        errors.append("min_requirements 必须是非负整数")
    if isinstance(manifest.get("required_sections"), list):
        for section in manifest["required_sections"]:
            if not isinstance(section, str) or not section.strip():
                errors.append("required_sections 元素必须是非空字符串")
    decisions = manifest.get("decisions", [])
    if isinstance(decisions, list):
        seen: set[str] = set()
        for index, decision in enumerate(decisions):
            if not isinstance(decision, dict):
                errors.append(f"decisions[{index}] 必须是对象")
                continue
            for key in ("decision_id", "required_terms", "obsolete_terms",
                        "scoped_terms", "whitelist", "required_occurrences",
                        "forbidden_occurrences"):
                if key not in decision:
                    errors.append(f"decisions[{index}] 缺少键: {key}")
            decision_id = decision.get("decision_id", "")
            if not isinstance(decision_id, str) or not re.fullmatch(r"D\d{2}", decision_id):
                errors.append(f"decisions[{index}] decision_id 格式错误: {decision_id!r}")
            elif decision_id in seen:
                errors.append(f"决策 ID 重复: {decision_id}")
            else:
                seen.add(decision_id)
            for key in ("required_terms", "obsolete_terms", "scoped_terms", "whitelist"):
                if not isinstance(decision.get(key), list):
                    errors.append(f"decisions[{index}].{key} 必须是 list")
            for key in ("required_occurrences", "forbidden_occurrences"):
                occurrences = decision.get(key)
                if not isinstance(occurrences, list):
                    errors.append(f"decisions[{index}].{key} 必须是 list")
                    continue
                for occ_index, occ in enumerate(occurrences):
                    label = f"decisions[{index}].{key}[{occ_index}]"
                    if not isinstance(occ, dict):
                        errors.append(f"{label} 必须是对象")
                        continue
                    for occ_key in ("pattern", "count", "sections", "reason"):
                        if occ_key not in occ:
                            errors.append(f"{label} 缺少键: {occ_key}")
                    if isinstance(occ.get("reason"), str) and not occ["reason"].strip():
                        errors.append(f"{label}.reason 必须是非空字符串")
                    errors.extend(_count_errors(occ.get("count")))
                    errors.extend(_sections_errors(label, occ.get("sections")))
        latest = manifest.get("latest_decision")
        if isinstance(latest, int) and latest >= 1:
            expected = [f"D{i:02d}" for i in range(1, latest + 1)]
            actual = sorted(seen)
            if actual != expected:
                errors.append(f"决策清单必须恰好覆盖 D01–D{latest:02d}，实际: {', '.join(actual) or '无'}")
    for key in ("code_contracts", "obsolete_code_contracts"):
        contracts = manifest.get(key, [])
        if not isinstance(contracts, list):
            continue
        for index, contract in enumerate(contracts):
            label = f"{key}[{index}]"
            if not isinstance(contract, dict):
                errors.append(f"{label} 必须是对象")
                continue
            for contract_key in ("pattern", "source_globs"):
                if contract_key not in contract:
                    errors.append(f"{label} 缺少键: {contract_key}")
            if isinstance(contract.get("pattern"), str):
                try:
                    re.compile(contract["pattern"])
                except re.error as exc:
                    errors.append(f"{label}.pattern 正则非法: {exc}")
            if isinstance(contract.get("source_globs"), list):
                for glob_pattern in contract["source_globs"]:
                    if not isinstance(glob_pattern, str):
                        errors.append(f"{label}.source_globs 元素必须是字符串")
            count = contract.get("count", 1)
            errors.extend(_count_errors(count))
    anchors = manifest.get("test_anchors", [])
    if isinstance(anchors, list):
        for index, anchor in enumerate(anchors):
            if not isinstance(anchor, dict):
                errors.append(f"test_anchors[{index}] 必须是对象")
                continue
            if "name" not in anchor or not isinstance(anchor["name"], str) \
                    or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", anchor["name"]):
                errors.append(f"test_anchors[{index}].name 必须是合法函数标识符")
            if "source_globs" not in anchor or not isinstance(anchor["source_globs"], list):
                errors.append(f"test_anchors[{index}].source_globs 必须是 list")
    barriers = manifest.get("barriers", [])
    if isinstance(barriers, list):
        for index, barrier in enumerate(barriers):
            if not isinstance(barrier, dict):
                errors.append(f"barriers[{index}] 必须是对象")
                continue
            if not isinstance(barrier.get("name"), str) or not barrier["name"].strip():
                errors.append(f"barriers[{index}].name 必须是非空字符串")
            command = barrier.get("command")
            if not isinstance(command, list) or not command \
                    or not all(isinstance(part, str) for part in command):
                errors.append(f"barriers[{index}].command 必须是非空字符串 list")
    return errors


def _mask_fenced_blocks(text: str) -> str:
    """把 CommonMark 代码围栏内容替换为等长空格，避免术语检查误扫代码。"""
    out: list[str] = []
    in_fence = False
    marker = ""
    opener_len = 0
    for line in text.splitlines(keepends=True):
        if in_fence:
            closer = re.match(r"^ {0,3}(`+|~+)[ \t]*$", line)
            if closer and closer.group(1)[0] == marker \
                    and len(closer.group(1)) >= opener_len:
                in_fence = False
                marker = ""
                opener_len = 0
            out.append(" " * len(line))
            continue
        opener = re.match(r"^ {0,3}(`+|~+)(.*)$", line)
        is_fence = bool(opener) and len(opener.group(1)) >= 3
        if is_fence and opener.group(1)[0] == "`" and "`" in opener.group(2):
            is_fence = False
        if is_fence:
            in_fence = True
            marker = opener.group(1)[0]
            opener_len = len(opener.group(1))
            out.append(" " * len(line))
        else:
            out.append(line)
    return "".join(out)


def _section_spans(masked: str) -> tuple[list[tuple[str, int, int]], list[str]]:
    """返回 (章节区间, 标题列表)。标题形如 '1. 背景与目标'。"""
    spans: list[tuple[str, int, int]] = []
    headings: list[str] = []
    offset = 0
    for line in masked.splitlines(keepends=True):
        match = re.match(r"^##\s+(\d+\..+?)\s*$", line.strip())
        if match:
            spans.append((match.group(1), offset, len(masked)))
            headings.append(match.group(1))
        offset += len(line)
    for index, (heading, start, _) in enumerate(spans):
        end = spans[index + 1][1] if index + 1 < len(spans) else len(masked)
        spans[index] = (heading, start, end)
    return spans, headings


def _section_at(spans: list[tuple[str, int, int]], offset: int) -> str:
    for heading, start, end in spans:
        if start <= offset < end:
            return heading.split(".", 1)[0]
    return "0"


def _bounded_findall(text: str, term: str) -> list[re.Match]:
    return list(re.finditer(_ID_BOUNDARY_L + re.escape(term) + _ID_BOUNDARY_R, text))


def _whitelist_spans(masked: str, terms: list[str]) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    for term in terms:
        for match in _bounded_findall(masked, term):
            spans.append((match.start(), match.end()))
    return spans


def _contains_whitelisted(match: re.Match, whitelist_spans: list[tuple[int, int]]) -> bool:
    return any(start <= match.start() and match.end() <= end for start, end in whitelist_spans)


def _count_matches(count: object, actual: int) -> str | None:
    if isinstance(count, int):
        if actual != count:
            return f"实际 {actual} 次，要求恰好 {count} 次"
        return None
    minimum = count.get("min")
    maximum = count.get("max")
    if minimum is not None and actual < minimum:
        return f"实际 {actual} 次，要求至少 {minimum} 次"
    if maximum is not None and actual > maximum:
        return f"实际 {actual} 次，要求至多 {maximum} 次"
    return None


def _check_occurrences(label: str, occurrences: list, masked: str,
                       spans: list[tuple[str, int, int]],
                       whitelist_spans: list[tuple[int, int]],
                       expect_zero: bool) -> list[str]:
    errors: list[str] = []
    for index, occurrence in enumerate(occurrences):
        if not isinstance(occurrence, dict):
            continue
        pattern = occurrence.get("pattern", "")
        count = occurrence.get("count", 1)
        sections = occurrence.get("sections", ["*"])
        try:
            compiled = re.compile(pattern)
        except re.error:
            continue
        matches = list(compiled.finditer(masked))
        selected = []
        for match in matches:
            if whitelist_spans and _contains_whitelisted(match, whitelist_spans):
                continue
            section = _section_at(spans, match.start())
            if "*" in sections or section in sections:
                selected.append(match)
        if expect_zero:
            if selected:
                errors.append(f"{label} 禁止 pattern 在章节 {sections} 出现，命中 {len(selected)} 次")
        else:
            problem = _count_matches(count, len(selected))
            if problem:
                errors.append(f"{label} pattern={pattern!r} 章节 {sections}: {problem}")
    return errors


def _search_source_files(repo_root: pathlib.Path, globs: list[str], pattern: str) -> tuple[int, list[pathlib.Path]]:
    compiled = re.compile(pattern)
    total = 0
    files: list[pathlib.Path] = []
    for glob_pattern in globs:
        for path in sorted(repo_root.glob(glob_pattern)):
            if not path.is_file():
                continue
            try:
                text = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            found = len(compiled.findall(text))
            if found:
                total += found
                files.append(path)
    return total, files


def _check_contracts(label: str, contracts: list, repo_root: pathlib.Path,
                     expect_zero: bool, spec_status: str) -> tuple[list[str], list[str]]:
    """校验代码契约 pattern 与代码一致；draft 状态降级为 warning（spec 可领先代码）。"""
    errors: list[str] = []
    warnings: list[str] = []
    relaxed = spec_status != "authoritative"
    for index, contract in enumerate(contracts):
        if not isinstance(contract, dict):
            continue
        pattern = contract.get("pattern", "")
        globs = contract.get("source_globs", [])
        count = contract.get("count", 1)
        try:
            actual, files = _search_source_files(repo_root, globs, pattern)
        except re.error:
            continue
        message: str | None = None
        if expect_zero:
            if actual:
                names = ", ".join(str(path.relative_to(repo_root)) for path in files[:5])
                message = f"{label}[{index}] 旧契约 pattern 必须零命中，实际 {actual} 次: {names}"
        else:
            problem = _count_matches(count, actual)
            if problem:
                message = f"{label}[{index}] pattern={pattern!r}: {problem}"
            else:
                requires_positive = (isinstance(count, int) and count > 0) \
                    or (isinstance(count, dict) and count.get("min", 0) > 0)
                if actual == 0 and requires_positive:
                    message = f"{label}[{index}] 未匹配到任何文件，请确认 source_globs"
        if message:
            if relaxed:
                warnings.append(message + "（draft：代码可未跟上 spec，暂不阻断）")
            else:
                errors.append(message)
    return errors, warnings


def _check_test_anchors(anchors: list, repo_root: pathlib.Path,
                        spec_status: str, errors: list[str], warnings: list[str]) -> None:
    for anchor in anchors:
        if not isinstance(anchor, dict):
            continue
        name = anchor.get("name", "")
        globs = anchor.get("source_globs", [])
        if not name:
            continue
        pattern = rf"func\s+{re.escape(name)}\s*\("
        actual, _ = _search_source_files(repo_root, globs, pattern)
        required = anchor.get("required", True)
        if actual == 0:
            message = f"测试锚点 {name} 在 {globs} 中不存在"
            if spec_status == "authoritative" and required:
                errors.append(message)
            else:
                warnings.append(message + "（draft/非必需，暂不阻断）")


def run_audit(manifest_path: str | pathlib.Path) -> tuple[list[str], list[str]]:
    manifest_path = pathlib.Path(manifest_path).resolve()
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except OSError as exc:
        return [f"无法读取 manifest: {exc}"], []
    except json.JSONDecodeError as exc:
        return [f"manifest JSON 非法: {exc}"], []

    errors: list[str] = _validate_manifest(manifest)
    warnings: list[str] = []
    if errors:
        return errors, warnings

    base_dir = manifest_path.parent
    spec_file = (base_dir / manifest["spec_file"]).resolve()
    repo_root = (base_dir / manifest["repo_root"]).resolve()
    try:
        raw_text = spec_file.read_text(encoding="utf-8")
    except OSError as exc:
        return [f"无法读取 spec: {exc}"], warnings

    masked = _mask_fenced_blocks(raw_text)
    spans, headings = _section_spans(masked)

    required_sections = manifest.get("required_sections", [])
    for section in required_sections:
        if section not in headings:
            errors.append(f"缺少必需章节: ## {section}")

    for term in manifest.get("metadata_terms", []):
        if term not in masked:
            errors.append(f"元信息缺失: {term}")

    for term in manifest.get("vague_terms", []):
        matches = _bounded_findall(masked, term)
        if matches:
            errors.append(f"模糊词 '{term}' 出现 {len(matches)} 次")

    for pattern in manifest.get("forbidden_patterns", []):
        try:
            matches = list(re.finditer(pattern, masked))
        except re.error as exc:
            errors.append(f"forbidden_patterns 正则非法: {pattern!r} ({exc})")
            continue
        if matches:
            errors.append(f"禁止 pattern 命中 {len(matches)} 次: {pattern!r}")

    requirement_prefix = manifest.get("requirement_prefix", "REQ-")
    definition_ids = [match.group(1) for match in re.finditer(
        r"(?m)^(?:[-*+]\s+|\d+\.\s+)"
        + _ID_BOUNDARY_L + re.escape(requirement_prefix) + r"(\d+)" + _ID_BOUNDARY_R,
        masked)]
    reference_ids = [match.group(1) for match in re.finditer(
        _ID_BOUNDARY_L + re.escape(requirement_prefix) + r"(\d+)" + _ID_BOUNDARY_R,
        masked)]
    duplicates = sorted({rid for rid in definition_ids if definition_ids.count(rid) > 1})
    if len(definition_ids) < manifest.get("min_requirements", 0):
        errors.append(f"需求定义至少 {manifest['min_requirements']} 个，实际 {len(definition_ids)} 个")
    if duplicates:
        errors.append(f"需求 ID 重复定义: {', '.join(requirement_prefix + rid for rid in duplicates)}")
    undefined = sorted({rid for rid in reference_ids if rid not in definition_ids})
    if undefined:
        errors.append(f"引用了未定义的需求 ID: {', '.join(requirement_prefix + rid for rid in undefined)}")

    latest = manifest["latest_decision"]
    decision_ids = sorted(decision.get("decision_id", "") for decision in manifest["decisions"])
    if decision_ids == [f"D{i:02d}" for i in range(1, latest + 1)]:
        for decision in manifest["decisions"]:
            decision_id = decision.get("decision_id", "")
            label = f"{decision_id}"
            whitelist_spans = _whitelist_spans(masked, decision.get("whitelist", []))
            for term in decision.get("required_terms", []):
                if not _bounded_findall(masked, term):
                    errors.append(f"{label} 必需术语 '{term}' 零命中")
            for term in decision.get("obsolete_terms", []):
                matches = _bounded_findall(masked, term)
                stale = [match for match in matches
                         if not _contains_whitelisted(match, whitelist_spans)]
                if stale:
                    errors.append(f"{label} 已废弃术语 '{term}' 命中 {len(stale)} 次")
            for term in decision.get("scoped_terms", []):
                for match in _bounded_findall(masked, term):
                    section = _section_at(spans, match.start())
                    if section == "0":
                        errors.append(f"{label} scoped 术语 '{term}' 出现在章节外")
            errors.extend(_check_occurrences(
                f"{label}.required_occurrences", decision.get("required_occurrences", []),
                masked, spans, whitelist_spans, expect_zero=False))
            errors.extend(_check_occurrences(
                f"{label}.forbidden_occurrences", decision.get("forbidden_occurrences", []),
                masked, spans, whitelist_spans, expect_zero=True))

    decision_tokens = list(re.finditer(_ID_BOUNDARY_L + r"D(\d{2})" + _ID_BOUNDARY_R, masked))
    for match in decision_tokens:
        number = int(match.group(1))
        if number > latest:
            errors.append(f"引用了未定义决策 D{number:02d}（latest=D{latest:02d}）")

    for match in re.finditer(r"D(\d{2})[–-]D(\d{2})", masked):
        start, end = int(match.group(1)), int(match.group(2))
        if start != 1 or end != latest:
            errors.append(f"决策范围 D{match.group(1)}–D{match.group(2)} 过期，应为 D01–D{latest:02d}")

    spec_status = manifest.get("spec_status", "draft")
    for label, contracts, expect_zero in (
        ("code_contracts", manifest.get("code_contracts", []), False),
        ("obsolete_code_contracts", manifest.get("obsolete_code_contracts", []), True),
    ):
        contract_errors, contract_warnings = _check_contracts(
            label, contracts, repo_root, expect_zero, spec_status)
        errors.extend(contract_errors)
        warnings.extend(contract_warnings)
    _check_test_anchors(manifest.get("test_anchors", []), repo_root,
                        spec_status, errors, warnings)
    return errors, warnings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="core-spec 结构审计器")
    parser.add_argument("manifest", nargs="?", default=None,
                        help=f"manifest 路径（默认脚本同目录 {DEFAULT_MANIFEST}）")
    args = parser.parse_args(argv)
    manifest_path = args.manifest or str(pathlib.Path(__file__).with_name(DEFAULT_MANIFEST))
    errors, warnings = run_audit(manifest_path)
    for warning in warnings:
        print(f"[WARN] {warning}")
    for error in errors:
        print(f"[FAIL] {error}")
    if errors:
        return 1
    print(f"PASS: {pathlib.Path(manifest_path).resolve()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
