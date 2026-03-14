#!/usr/bin/env python3
# review_by: 2026-09-10
"""
PostToolUse hook for Edit/Write operations on .dart files.

After a Dart file is edited, runs targeted invariant checks relevant to the
edited file. Also detects if any documentation references the edited file and
warns about potential staleness.

Combines Phase 4f (post-edit enforcement) and 4g (doc staleness detection).

Exit codes:
  0 = all checks pass (or non-dart file)
"""
# Hook Contract:
#   Event:        PostToolUse (Edit, Write)
#   Matcher:      tool_name in ("Edit", "Write") and file_path ends with ".dart"
#   Input:        {"tool_name": "Edit"|"Write", "tool_input": {"file_path": "..."}} via stdin
#   Output:       Plain text warnings on stdout (invariant failures, stale doc hints);
#                 never blocks (advisory only); silent on clean files
#   Side effects: Runs targeted `dart run .claude/invariants/*.dart` based on file path;
#                 scans docs/ for references to the edited file for staleness warnings
#   Dependencies: dart CLI, .claude/invariants/*.dart
import json
import os
import re
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
INVARIANTS_DIR = PROJECT_ROOT / ".claude" / "invariants"

# Map: file path pattern -> relevant invariant(s)
INVARIANT_TRIGGERS = {
    "/src/": ["public-api-surface.dart"],
    "pubspec.yaml": ["circular-deps.dart"],
    "/repositories/": ["interface-naming.dart"],
    "interface": ["interface-naming.dart"],
    ".g.dart": ["generated-file-check.dart"],
    "/adapters/": ["layer-deps.dart"],
    "/bindings/": ["layer-deps.dart"],
    "/generators/": ["layer-deps.dart"],
    "packages/": ["layer-deps.dart"],
}

# Doc roots to scan for references to edited files
DOC_ROOTS = [
    "docs/",
    "packages/",  # scoped CLAUDE.md files
]


def find_relevant_invariants(file_path):
    """Determine which invariants are relevant for the edited file."""
    relevant = set()
    for pattern, invariants in INVARIANT_TRIGGERS.items():
        if pattern in file_path:
            relevant.update(invariants)
    return sorted(relevant)


def run_invariant(name):
    """Run a single invariant and return (passed, output)."""
    script = INVARIANTS_DIR / name
    if not script.exists():
        return True, ""
    result = subprocess.run(
        ["dart", "run", str(script)],
        capture_output=True, text=True,
        cwd=str(PROJECT_ROOT),
    )
    return result.returncode == 0, result.stdout.strip()


def find_referencing_docs(file_path):
    """Find documentation files that reference the edited source file.

    Searches for the file path (or key parts of it) in doc files to detect
    potential staleness.
    """
    stale_docs = []

    # Extract meaningful path components for searching
    rel_path = file_path
    if rel_path.startswith(str(PROJECT_ROOT)):
        rel_path = os.path.relpath(rel_path, str(PROJECT_ROOT))

    # Search patterns: full relative path, or just the filename
    filename = os.path.basename(rel_path)
    search_terms = [rel_path, filename]

    for doc_root in DOC_ROOTS:
        root_path = PROJECT_ROOT / doc_root
        if not root_path.exists():
            continue

        for doc_file in root_path.rglob("*.md"):
            # Skip archives
            if "/archives/" in str(doc_file):
                continue

            try:
                content = doc_file.read_text()
            except (OSError, UnicodeDecodeError):
                continue

            for term in search_terms:
                if term in content:
                    doc_rel = os.path.relpath(str(doc_file), str(PROJECT_ROOT))
                    stale_docs.append(doc_rel)
                    break

    return sorted(set(stale_docs))


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    if tool_name not in ("Edit", "Write"):
        sys.exit(0)

    file_path = tool_input.get("file_path", "")
    if not file_path.endswith(".dart"):
        sys.exit(0)

    # Phase 4f: Run relevant invariants
    relevant = find_relevant_invariants(file_path)
    failures = []

    if relevant:
        for inv in relevant:
            passed, output = run_invariant(inv)
            if not passed:
                failures.append({"invariant": inv, "output": output})

    # Phase 4g: Check for potentially stale docs
    stale_docs = find_referencing_docs(file_path)

    # Asymmetric output: silent on success, verbose on issues
    if failures:
        print(f"\n⚠️  Post-edit invariant check: {len(failures)} failure(s)")
        for f in failures:
            print(f"  FAIL: {f['invariant']}")
            # Show first few lines of output
            for line in f["output"].split("\n")[:5]:
                if line.strip():
                    print(f"    {line}")

    if stale_docs:
        print(f"\n📝 {len(stale_docs)} doc(s) may be stale after editing {os.path.basename(file_path)}:")
        for doc in stale_docs[:5]:
            print(f"  → {doc}")
        if len(stale_docs) > 5:
            print(f"  ... and {len(stale_docs) - 5} more")
        print("  Consider re-verifying or updating these docs.")

    sys.exit(0)


if __name__ == "__main__":
    main()
