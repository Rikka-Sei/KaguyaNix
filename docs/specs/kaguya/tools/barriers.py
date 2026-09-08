#!/usr/bin/env python3
"""core-spec 验收屏障运行器模板。

用法：python barriers.py [path/to/audit_manifest.json]

逐个执行 manifest.barriers 中的命令；任一屏障失败立即停止并返回非零。
spec 为 authoritative 状态时，本命令必须全绿；draft 状态允许为空。
"""
from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys

DEFAULT_MANIFEST = "audit_manifest.json"


def run_barriers(manifest_path: str | pathlib.Path) -> int:
    manifest_path = pathlib.Path(manifest_path).resolve()
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"[FAIL] 无法读取 manifest: {exc}", file=sys.stderr)
        return 1
    barriers = manifest.get("barriers", [])
    if not barriers:
        print("[SKIP] manifest 未声明任何屏障")
        return 0
    repo_root = (manifest_path.parent / manifest.get("repo_root", "../..")).resolve()
    for barrier in barriers:
        name = barrier.get("name", "未命名屏障")
        command = barrier.get("command")
        if not isinstance(command, list) or not command:
            print(f"[FAIL] 屏障 '{name}' command 非法", file=sys.stderr)
            return 1
        print(f"[BARRIER] {name}", flush=True)
        completed = subprocess.run(command, cwd=repo_root, check=False)
        if completed.returncode != 0:
            print(f"[FAIL] 屏障 '{name}' 退出码 {completed.returncode}", file=sys.stderr)
            return completed.returncode or 1
        print(f"[PASS] {name}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="core-spec 验收屏障运行器")
    parser.add_argument("manifest", nargs="?", default=None,
                        help=f"manifest 路径（默认脚本同目录 {DEFAULT_MANIFEST}）")
    args = parser.parse_args(argv)
    manifest_path = args.manifest or str(pathlib.Path(__file__).with_name(DEFAULT_MANIFEST))
    return run_barriers(manifest_path)


if __name__ == "__main__":
    sys.exit(main())
