#!/usr/bin/env python3
# review_by: 2026-09-10
"""
PreToolUse hook for test commands in a Melos monorepo.

STRATEGY: Intercept full-suite test commands and redirect to
smart-test-run.py (git-diff detection + content-hash caching). Let targeted
test runs (specific files or subdirectories) pass through directly as native
test commands, with --file-reporter injected for result capture.

Also intercepts smart-test-run.py --all to strip the --all flag, preventing
bypass of smart detection.

Commands that get REDIRECTED to smart runner (full suite):
  - flutter test                                    -> smart-test-run.py
  - dart test                                       -> smart-test-run.py
  - melos run test:dart                             -> smart-test-run.py
  - melos run test:flutter                          -> smart-test-run.py
  - melos run test                                  -> smart-test-run.py
  - flutter test test/                              -> smart-test-run.py
  - dart test test/                                 -> smart-test-run.py

Commands that PASS THROUGH (with --file-reporter injected):
  - flutter test test/src/store_test.dart             (targeted file)
  - dart test test/src/some_test.dart                (targeted file)
  - flutter test test/unit/                         (targeted subdirectory)
  - dart test test/unit/                            (targeted subdirectory)

Commands that PASS THROUGH unchanged:
  - python3 .claude/hooks/smart-test-run.py         (already smart, no --all)
  - python3 .claude/hooks/rerun-failures.py         (already smart)
  - flutter test --help                             (info only)
  - dart test --help                                (info only)

Commands that get MODIFIED:
  - python3 smart-test-run.py --all                 -> strips --all flag
"""
# Hook Contract:
#   Event:        PreToolUse (Bash)
#   Matcher:      tool_name == "Bash" and ("flutter test"|"dart test"|"melos run test") in command
#   Input:        {"tool_name": "Bash", "tool_input": {"command": "..."}} via stdin
#   Output:       {"hookSpecificOutput": {"hookEventName": "PreToolUse",
#                  "permissionDecision": "allow", "updatedInput": {"command": "..."}}}
#                 (only emitted when command is modified; silent for no-op passes)
#   Side effects: Full-suite runs redirected to smart-test-run.py;
#                 targeted runs get --file-reporter injected for result capture
#   Dependencies: smart-test-run.py (same directory)
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent

# Shell tokens that are NOT test paths (pipes, redirects, subshells)
SHELL_NOISE = {"2>&1", "&&", "||", "|", ">", ">>", "<", "<<", ";", "(", ")", "{", "}"}


def extract_test_segment(command):
    """Extract just the test args from flutter test or dart test, stripping pipes and shell operators.

    'flutter test --exclude-tags=golden 2>&1 | tail -5'
    -> '--exclude-tags=golden'

    'dart test test/unit/models/ && echo done'
    -> 'test/unit/models/'
    """
    # Try flutter test first, then dart test
    match = re.search(r"(?:flutter|dart) test\b(.*)", command)
    if not match:
        return ""

    remainder = match.group(1)

    # Strip at the first shell operator (|, &&, ||, ;, >, 2>&1)
    clean = re.split(r"\s+(?:2>&1|\|{1,2}|&&|;|>{1,2}|<{1,2})\s*", remainder)[0]

    return clean.strip()


# All test flags that take a separate value argument (--flag value).
FLAGS_WITH_VALUES = {
    # Test filtering
    "--name", "-n", "--plain-name",
    "--tags", "-t", "--exclude-tags", "-x",
    # Execution
    "--concurrency", "-j", "--timeout",
    "--test-randomize-ordering-seed",
    "--total-shards", "--shard-index",
    # Reporting
    "--reporter", "-r", "--file-reporter",
    # Build config
    "--dart-define", "-D", "--dart-define-from-file",
    "--device-user", "--flavor",
    # Coverage
    "--coverage-path", "--coverage-package",
    # Debug
    "--dds-port",
    # Device
    "--device-id", "-d",
}


def extract_test_paths(test_args):
    """Extract test file/directory paths from test args, ignoring flags.

    '--exclude-tags=golden test/src/store_test.dart'
    -> ['test/src/store_test.dart']

    '--name "some test"'
    -> []
    """
    if not test_args:
        return []

    tokens = test_args.split()
    paths = []
    skip_next = False

    for token in tokens:
        if skip_next:
            skip_next = False
            continue
        # Skip flags and their values
        if token.startswith("-"):
            # For flags without = syntax, check if next token is the value
            if "=" not in token and token in FLAGS_WITH_VALUES:
                skip_next = True
            continue
        # Skip shell noise that leaked through
        if token in SHELL_NOISE or re.match(r"^\d+>&\d+$", token):
            continue
        paths.append(token)

    return paths


def is_full_suite_run(test_paths):
    """Determine if the test command targets the full suite.

    A "full suite" run is when:
    - No specific test paths are given (bare 'flutter test'/'dart test' or flags-only)
    - The only path is the root 'test/' directory

    Returns True if the command should be redirected to the smart runner.
    """
    if not test_paths:
        return True
    normalized = {p.rstrip("/") for p in test_paths}
    return normalized.issubset({"test"})


def inject_file_reporter(command):
    """Inject --file-reporter into a test command for result capture.

    Targeted passthrough runs still get their results recorded by the
    capture-test-results.py PostToolUse hook via the injected reporter.
    All original flags (--coverage, --reporter, etc.) are preserved.
    """
    timestamp = datetime.now().strftime("%Y-%m-%dT%H-%M-%S-%f")
    report_dir = SCRIPT_DIR.parent.parent / "test-history" / "reports"
    report_path = report_dir / f"{timestamp}.jsonl"
    os.makedirs(report_dir, exist_ok=True)

    # Replace the first occurrence of 'flutter test' or 'dart test'
    for test_cmd in ["flutter test", "dart test"]:
        if test_cmd in command:
            return command.replace(
                test_cmd,
                f"{test_cmd} --file-reporter json:{report_path}",
                1,
            )
    return command


def emit_allow(command):
    """Emit a hook response that replaces the command."""
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {"command": command},
        }
    }))


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")

    if tool_name != "Bash":
        sys.exit(0)

    # === INTERCEPT: smart-test-run.py --all -> strip --all flag ===
    if "smart-test-run.py" in command and "--all" in command:
        modified = command.replace("--all", "").strip()
        modified = re.sub(r"  +", " ", modified)
        emit_allow(modified)
        sys.exit(0)

    # === INTERCEPT: melos run test commands -> redirect to smart runner ===
    if re.search(r"melos\s+run\s+test(?::dart|:flutter)?(?:\s|$)", command):
        smart_cmd = f"python3 {SCRIPT_DIR / 'smart-test-run.py'}"
        emit_allow(smart_cmd)
        sys.exit(0)

    # Skip commands that don't contain flutter test or dart test
    has_flutter_test = "flutter test" in command
    has_dart_test = "dart test" in command and "dart test" not in "dart test_" in command
    # More precise check for 'dart test' (not 'dart test_something')
    has_dart_test = bool(re.search(r"\bdart test\b", command))

    if not has_flutter_test and not has_dart_test:
        sys.exit(0)

    # Already using smart runner or rerun-failures -- pass through
    if "smart-test-run.py" in command or "rerun-failures.py" in command:
        sys.exit(0)

    # Help/version -- pass through
    if "--help" in command or "--version" in command:
        sys.exit(0)

    # === DECISION: redirect full suite OR pass through targeted runs ===
    args = extract_test_segment(command)
    test_paths = extract_test_paths(args)

    if is_full_suite_run(test_paths):
        # Full suite -> redirect to smart runner (git-diff + caching)
        smart_cmd = f"python3 {SCRIPT_DIR / 'smart-test-run.py'}"
        emit_allow(smart_cmd)
    else:
        # Targeted run -> pass through with --file-reporter for result capture
        modified = inject_file_reporter(command)
        emit_allow(modified)

    sys.exit(0)


if __name__ == "__main__":
    main()
