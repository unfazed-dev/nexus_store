#!/usr/bin/env python3
# review_by: 2026-09-07
"""
SubagentStop hook — validates sub-agent output meets isolation contract.

Checks:
  1. Output is parseable JSON
  2. Output is ≤2000 tokens (~8000 chars)
  3. Output contains required fields: status, summary, files_modified
  4. If kb_indexed=true, validates search_keys is a non-empty list

Exit: writes JSON to stdout per hook contract.
"""
# Hook Contract:
#   Event:        SubagentStop
#   Matcher:      agent_name in {"doc-gardener", "drift-detector", "gc-agent"}
#   Input:        {"last_assistant_message": "...", "agent_name": "..."} via stdin
#   Output:       {"decision": "block", "reason": "..."} on stdout when checks fail;
#                 silent (exit 0) on pass or non-harness agents
#   Checks:       1) output is valid JSON; 2) output ≤ 2000 tokens (~8000 chars);
#                 3) output contains required fields: status, summary, files_modified;
#                 4) if kb_indexed=true, search_keys must be non-empty list
#   Side effects: Blocks harness agent outputs violating isolation contract
#   Dependencies: none (stdlib only)
import json
import sys

MAX_CHARS = 8000  # ~2000 tokens at 4 chars/token
REQUIRED_FIELDS = {"status", "summary", "files_modified"}
# KB-indexed format requires these additional fields when kb_indexed is True
KB_INDEXED_FIELDS = {"kb_indexed", "search_keys"}


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        # Can't parse hook input — allow through
        sys.exit(0)

    # SubagentStop provides last_assistant_message
    last_message = input_data.get("last_assistant_message", "")
    if not last_message:
        sys.exit(0)

    # Only validate harness agents (doc-gardener, drift-detector, gc-agent)
    agent_name = input_data.get("agent_name", "")
    harness_agents = {"doc-gardener", "drift-detector", "gc-agent"}
    if agent_name not in harness_agents:
        sys.exit(0)

    # Check 1: Is it valid JSON?
    try:
        output = json.loads(last_message)
    except (json.JSONDecodeError, TypeError):
        result = {
            "decision": "block",
            "reason": f"Sub-agent '{agent_name}' output is not valid JSON. Isolation contract requires structured JSON output."
        }
        print(json.dumps(result))
        sys.exit(0)

    # Check 2: Size limit
    if len(last_message) > MAX_CHARS:
        result = {
            "decision": "block",
            "reason": f"Sub-agent '{agent_name}' output exceeds 2000 token limit ({len(last_message)} chars / ~{len(last_message)//4} tokens). Summarize results."
        }
        print(json.dumps(result))
        sys.exit(0)

    # Check 3: Required fields
    missing = REQUIRED_FIELDS - set(output.keys())
    if missing:
        result = {
            "decision": "block",
            "reason": f"Sub-agent '{agent_name}' output missing required fields: {', '.join(sorted(missing))}. Required: status, summary, files_modified."
        }
        print(json.dumps(result))
        sys.exit(0)

    # Check 4: KB-indexed format validation (when kb_indexed is True)
    if output.get("kb_indexed") is True:
        missing_kb = KB_INDEXED_FIELDS - set(output.keys())
        if missing_kb:
            result = {
                "decision": "block",
                "reason": f"Sub-agent '{agent_name}' declared kb_indexed=true but missing fields: {', '.join(sorted(missing_kb))}. Required: kb_indexed, search_keys."
            }
            print(json.dumps(result))
            sys.exit(0)

        search_keys = output.get("search_keys")
        if not isinstance(search_keys, list) or len(search_keys) == 0:
            result = {
                "decision": "block",
                "reason": f"Sub-agent '{agent_name}' has kb_indexed=true but search_keys must be a non-empty list of strings."
            }
            print(json.dumps(result))
            sys.exit(0)

    # All checks pass — allow
    sys.exit(0)


if __name__ == "__main__":
    main()
