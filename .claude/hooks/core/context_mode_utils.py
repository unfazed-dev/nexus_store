#!/usr/bin/env python3
# review_by: 2026-09-13
"""
Shared utilities for Context Mode integration in hooks.

Provides detection of Context Mode MCP server and sidecar logging
for informational hooks that compress output when CM is active.
"""
import json
import os
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
MCP_CONFIG = PROJECT_ROOT / ".mcp.json"
PLUGINS_CONFIG = Path.home() / ".claude" / "plugins" / "installed_plugins.json"
SIDECAR_LOG_DIR = PROJECT_ROOT / ".claude" / "hooks" / "logs"


def is_context_mode_active():
    """Check if Context Mode is active via plugin marketplace or .mcp.json."""
    # Strategy 1: Plugin marketplace (current install method)
    try:
        if PLUGINS_CONFIG.exists():
            with open(PLUGINS_CONFIG) as f:
                data = json.load(f)
            plugins = data.get("plugins", {})
            if any(k.startswith("context-mode@") for k in plugins):
                return True
    except (json.JSONDecodeError, OSError):
        pass

    # Strategy 2: .mcp.json (legacy install method)
    try:
        if MCP_CONFIG.exists():
            with open(MCP_CONFIG) as f:
                config = json.load(f)
            servers = config.get("mcpServers", {})
            if "context-mode" in servers:
                return True
    except (json.JSONDecodeError, OSError):
        pass

    return False


def write_sidecar_log(hook_name, detail):
    """Write detailed hook output to a sidecar log file.

    Appends timestamped entries to .claude/hooks/logs/<hook_name>.log.
    Rotates when file exceeds 512 KB.
    """
    try:
        SIDECAR_LOG_DIR.mkdir(parents=True, exist_ok=True)
        log_file = SIDECAR_LOG_DIR / f"{hook_name}.log"

        # Rotate if too large
        max_size = 512 * 1024  # 512 KB
        if log_file.exists() and log_file.stat().st_size > max_size:
            # Keep last half
            content = log_file.read_text()
            lines = content.split("\n")
            half = len(lines) // 2
            log_file.write_text("\n".join(lines[half:]))

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        entry = f"[{timestamp}] {detail}\n"

        with open(log_file, "a", encoding="utf-8") as f:
            f.write(entry)

    except OSError:
        pass  # Silent on log errors


def compress_output(hook_name, summary, detail):
    """Return compressed or full output based on Context Mode status.

    When Context Mode is active:
      - Writes full detail to sidecar log
      - Returns one-line summary for context window

    When Context Mode is inactive:
      - Returns full detail as-is
    """
    if is_context_mode_active():
        write_sidecar_log(hook_name, detail)
        return summary
    return detail
