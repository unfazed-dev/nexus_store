#!/usr/bin/env python3
# review_by: 2026-09-13
"""Orchestrator runner with Context Mode compression.

Wraps orchestrator invocations to compress intermediate output when Context
Mode is active. Full verbose output (stderr, debug lines) goes to sidecar
log; only the JSON contract is returned to stdout.

When Context Mode is inactive, behaves as a transparent pass-through.

Usage:
    python3 .claude/orchestrators/run_orchestrator.py <orchestrator> [args...]

Examples:
    python3 .claude/orchestrators/run_orchestrator.py pre-commit-check.sh
    python3 .claude/orchestrators/run_orchestrator.py test-and-report.py --staged
    python3 .claude/orchestrators/run_orchestrator.py harness-maintenance.py --all
"""

import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent

# Add hooks/core to path for context_mode_utils
sys.path.insert(0, str(PROJECT_ROOT / ".claude" / "hooks" / "core"))

from context_mode_utils import compress_output, is_context_mode_active


ORCHESTRATOR_MAP = {
    "pre-commit-check.sh": {"cmd": ["bash"], "timeout": 300},
    "test-and-report.py": {"cmd": [sys.executable], "timeout": 600},
    "harness-maintenance.py": {"cmd": [sys.executable], "timeout": 120},
}


def extract_json(output: str) -> tuple:
    """Extract JSON object from output, return (json_str, non_json_lines).

    Scans output for the first line starting with '{' and attempts to parse
    a complete JSON object from that point forward.
    """
    lines = output.split("\n")
    json_start = None
    for i, line in enumerate(lines):
        if line.strip().startswith("{"):
            json_start = i
            break

    if json_start is None:
        return None, output

    pre_json = "\n".join(lines[:json_start]).strip()
    json_candidate = "\n".join(lines[json_start:])

    try:
        data = json.loads(json_candidate)
        return json.dumps(data, indent=2), pre_json
    except json.JSONDecodeError:
        # Try parsing just until we find a complete JSON object
        # by accumulating lines
        accumulated = ""
        for line in lines[json_start:]:
            accumulated += line + "\n"
            try:
                data = json.loads(accumulated)
                return json.dumps(data, indent=2), pre_json
            except json.JSONDecodeError:
                continue

    return None, output


def run_orchestrator(name: str, extra_args: list) -> int:
    """Run an orchestrator and handle output based on CM status."""
    if name not in ORCHESTRATOR_MAP:
        print(f"Unknown orchestrator: {name}", file=sys.stderr)
        print(f"Available: {', '.join(sorted(ORCHESTRATOR_MAP.keys()))}", file=sys.stderr)
        return 1

    config = ORCHESTRATOR_MAP[name]
    script_path = str(SCRIPT_DIR / name)
    cmd = config["cmd"] + [script_path] + extra_args

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(PROJECT_ROOT),
        timeout=config["timeout"],
    )

    stdout = result.stdout.strip()
    stderr = result.stderr.strip()

    # Extract JSON contract from stdout
    json_str, non_json = extract_json(stdout)

    if not is_context_mode_active() or json_str is None:
        # No CM or no JSON found — pass through everything
        if stdout:
            print(stdout)
        if stderr:
            print(stderr, file=sys.stderr)
        return result.returncode

    # CM active — compress non-JSON output, return only JSON contract
    full_detail = []
    if non_json:
        full_detail.append(f"[pre-json output]\n{non_json}")
    if stderr:
        full_detail.append(f"[stderr]\n{stderr}")

    if full_detail:
        detail_text = f"orchestrator={name} exit={result.returncode}\n" + "\n".join(full_detail)
        # Use compress_output to sidecar-log the verbose detail
        compress_output(f"orchestrator-{name}", f"[CM] {name}: see sidecar log", detail_text)

    # Return only the clean JSON contract
    print(json_str)
    return result.returncode


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 .claude/orchestrators/run_orchestrator.py <orchestrator> [args...]")
        print(f"Available: {', '.join(sorted(ORCHESTRATOR_MAP.keys()))}")
        sys.exit(1)

    name = sys.argv[1]
    extra_args = sys.argv[2:]

    try:
        exit_code = run_orchestrator(name, extra_args)
    except subprocess.TimeoutExpired:
        print(json.dumps({
            "status": "fail",
            "checks": {},
            "recommendation": f"Orchestrator '{name}' timed out",
            "action_needed": True,
            "details": [f"{name} exceeded timeout"],
            "accepted": False,
        }, indent=2))
        exit_code = 1

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
