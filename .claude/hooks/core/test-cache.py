#!/usr/bin/env python3
# review_by: 2026-09-14
"""
Content-addressable test result cache for the nexus_store monorepo.

Tracks file content hashes to determine which tests can be safely skipped
because their source dependencies haven't changed since the last PASS.

Architecture:
    For each test file, compute a composite hash of:
      1. The test file itself
      2. The package name (scoping cache per-package)
      3. All direct imports the test depends on
    Store: composite_hash -> {result, timestamp, test_file}

    Before running, check if the composite hash is already cached as PASS.
    After a successful run, update the cache with new hashes.

Cache storage: .claude/test-history/test-cache.json

Usage:
    # Filter a list of test files, returning only those needing re-run
    python3 .claude/hooks/test-cache.py filter <test_file> [<test_file> ...]

    # Update cache after a successful test run
    python3 .claude/hooks/test-cache.py update <test_file> [<test_file> ...]

    # Show cache statistics
    python3 .claude/hooks/test-cache.py stats

    # Invalidate specific test files
    python3 .claude/hooks/test-cache.py invalidate <test_file> [<test_file> ...]

    # Purge all cache entries
    python3 .claude/hooks/test-cache.py purge

    # Purge entries older than N hours (default: 48)
    python3 .claude/hooks/test-cache.py gc [--max-age=48]

I/O:
    Stdin:  none (CLI tool)
    Stdout: filtered file paths (filter mode, one per line); stats or confirmation otherwise
    Exit:   0 = success; 1 = unknown command

Dependencies:
    .claude/test-history/test-map.json   (for composite hash computation)
    .claude/test-history/test-cache.json (cache storage; created on first update)
"""
import hashlib
import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
CACHE_PATH = PROJECT_ROOT / ".claude" / "test-history" / "test-cache.json"
TEST_MAP_PATH = PROJECT_ROOT / ".claude" / "test-history" / "test-map.json"
MAX_CACHE_AGE_HOURS = 48  # Default TTL for cache entries
MAX_CACHE_ENTRIES = 2000  # Safety cap


def file_hash(filepath):
    """Compute SHA-256 hash of a file's contents. Returns None if file missing."""
    try:
        abs_path = filepath if os.path.isabs(filepath) else os.path.join(str(PROJECT_ROOT), filepath)
        with open(abs_path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()[:16]  # 16 hex chars = 64 bits
    except (OSError, IOError):
        return None


def detect_package_name(test_file):
    """Extract the package name from a test file path like packages/xxx/test/..."""
    if test_file.startswith("packages/"):
        parts = test_file.split("/")
        if len(parts) >= 2:
            return parts[1]
    return None


def get_test_dependencies(test_file, test_map=None):
    """Get all source files that a test file depends on.

    Extracts direct imports from the test file itself.
    Uses test-map.json reverse index if available.
    """
    deps = set()

    # Use test-map.json if available
    if test_map:
        mappings = test_map.get("mappings", {})
        for source, tests in mappings.items():
            if test_file in tests:
                deps.add(source)

    # Extract direct imports from the test file
    abs_test = os.path.join(str(PROJECT_ROOT), test_file)
    try:
        with open(abs_test, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("//"):
                    continue
                if line.startswith("import"):
                    # Match any package import
                    match = re.search(r"'package:([^/]+)/(.+)'", line)
                    if match:
                        pkg_name = match.group(1)
                        # Try to resolve to a file in packages/
                        pkg_dir = PROJECT_ROOT / "packages" / pkg_name
                        if pkg_dir.is_dir():
                            deps.add(f"packages/{pkg_name}/lib/{match.group(2)}")
                    # Match relative imports
                    match = re.search(r"'([^']+\.dart)'", line)
                    if match and not match.group(1).startswith("package:"):
                        rel_import = match.group(1)
                        # Resolve relative to test file directory
                        test_dir = os.path.dirname(abs_test)
                        resolved = os.path.normpath(os.path.join(test_dir, rel_import))
                        if os.path.exists(resolved):
                            try:
                                deps.add(str(Path(resolved).relative_to(PROJECT_ROOT)))
                            except ValueError:
                                pass
                elif re.match(r"^(class |void |Future |final |const |var |typedef |enum |mixin |extension |sealed )", line):
                    break
    except (OSError, UnicodeDecodeError):
        pass

    return sorted(deps)


def compute_composite_hash(test_file, test_map=None):
    """Compute a composite hash of a test file and all its dependencies.

    Includes package name in the hash so caches are scoped per-package.
    Returns (composite_hash, dep_count) or (None, 0) if test file missing.
    """
    # Hash the test file itself
    test_h = file_hash(test_file)
    if test_h is None:
        return None, 0

    # Include package name for per-package scoping
    pkg_name = detect_package_name(test_file) or "root"

    # Get and hash all dependencies
    deps = get_test_dependencies(test_file, test_map)
    dep_hashes = [f"pkg:{pkg_name}", test_h]

    for dep in deps:
        h = file_hash(dep)
        if h is not None:
            dep_hashes.append(h)
        else:
            # Dependency missing — include a marker so hash changes
            dep_hashes.append(f"MISSING:{dep}")

    # Composite hash = hash of all individual hashes joined
    composite = hashlib.sha256("|".join(dep_hashes).encode()).hexdigest()[:20]
    return composite, len(deps)


def load_cache():
    """Load the cache from disk."""
    if not CACHE_PATH.exists():
        return {}
    try:
        with open(CACHE_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return {}


def save_cache(cache):
    """Save the cache to disk."""
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    try:
        with open(CACHE_PATH, "w", encoding="utf-8") as f:
            json.dump(cache, f, indent=2, sort_keys=True)
    except OSError as e:
        print(f"Warning: Could not save cache: {e}", file=sys.stderr)


def load_test_map():
    """Load the test map index."""
    if not TEST_MAP_PATH.exists():
        return None
    try:
        with open(TEST_MAP_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def filter_tests(test_files, verbose=False):
    """Filter test files, returning only those that need to be re-run.

    A test can be skipped if:
    1. Its composite hash exists in the cache
    2. The cached result is PASS
    3. The cache entry is not expired
    """
    cache = load_cache()
    test_map = load_test_map()  # Optional in monorepo — works without it

    need_run = []
    skipped = []
    now = time.time()
    max_age_seconds = MAX_CACHE_AGE_HOURS * 3600

    for test_file in test_files:
        composite_hash, dep_count = compute_composite_hash(test_file, test_map)

        if composite_hash is None:
            # Can't hash — must run
            need_run.append(test_file)
            if verbose:
                print(f"  RUN  {test_file} (file not found)")
            continue

        # Check cache
        cache_key = f"{test_file}:{composite_hash}"
        entry = cache.get(cache_key)

        if entry and entry.get("result") == "pass":
            # Check age
            cached_time = entry.get("timestamp", 0)
            age = now - cached_time
            if age < max_age_seconds:
                skipped.append(test_file)
                if verbose:
                    age_min = age / 60
                    print(f"  SKIP {test_file} (passed {age_min:.0f}m ago, {dep_count} deps)")
                continue
            else:
                if verbose:
                    print(f"  RUN  {test_file} (cache expired, {age/3600:.1f}h old)")
        elif verbose:
            print(f"  RUN  {test_file} (no cache hit, {dep_count} deps)")

        need_run.append(test_file)

    if skipped and not verbose:
        print(f"Cache: skipping {len(skipped)} already-passed tests, running {len(need_run)}")
    elif verbose:
        print(f"\nSummary: {len(skipped)} skipped, {len(need_run)} need run")

    return need_run


def update_cache(test_files, result="pass"):
    """Update cache entries for test files that passed.

    Computes fresh composite hashes and stores them.
    """
    cache = load_cache()
    test_map = load_test_map()  # Optional in monorepo

    now = time.time()
    updated = 0

    for test_file in test_files:
        composite_hash, dep_count = compute_composite_hash(test_file, test_map)
        if composite_hash is None:
            continue

        cache_key = f"{test_file}:{composite_hash}"
        cache[cache_key] = {
            "result": result,
            "timestamp": now,
            "test_file": test_file,
            "dep_count": dep_count,
            "hash": composite_hash,
            "updated": datetime.now().isoformat(),
        }
        updated += 1

    # Enforce size limit — evict oldest entries
    if len(cache) > MAX_CACHE_ENTRIES:
        sorted_entries = sorted(cache.items(), key=lambda x: x[1].get("timestamp", 0))
        excess = len(cache) - MAX_CACHE_ENTRIES
        for key, _ in sorted_entries[:excess]:
            del cache[key]

    save_cache(cache)
    return updated


def invalidate_tests(test_files):
    """Remove cache entries for specific test files."""
    cache = load_cache()
    removed = 0
    keys_to_remove = []

    for key, entry in cache.items():
        if entry.get("test_file") in test_files:
            keys_to_remove.append(key)

    for key in keys_to_remove:
        del cache[key]
        removed += 1

    save_cache(cache)
    return removed


def gc_cache(max_age_hours=None):
    """Remove expired cache entries."""
    if max_age_hours is None:
        max_age_hours = MAX_CACHE_AGE_HOURS

    cache = load_cache()
    now = time.time()
    max_age_seconds = max_age_hours * 3600

    original_size = len(cache)
    keys_to_remove = []

    for key, entry in cache.items():
        age = now - entry.get("timestamp", 0)
        if age > max_age_seconds:
            keys_to_remove.append(key)

    for key in keys_to_remove:
        del cache[key]

    save_cache(cache)
    return original_size, len(cache)


def print_stats():
    """Print cache statistics."""
    cache = load_cache()

    if not cache:
        print("Test cache is empty.")
        return

    now = time.time()
    pass_count = sum(1 for e in cache.values() if e.get("result") == "pass")
    fail_count = sum(1 for e in cache.values() if e.get("result") == "fail")

    ages = [(now - e.get("timestamp", 0)) / 3600 for e in cache.values()]
    newest = min(ages) if ages else 0
    oldest = max(ages) if ages else 0

    # Unique test files
    unique_tests = set(e.get("test_file", "") for e in cache.values())
    unique_tests.discard("")

    # Dep count stats
    dep_counts = [e.get("dep_count", 0) for e in cache.values()]
    avg_deps = sum(dep_counts) / len(dep_counts) if dep_counts else 0

    print()
    print("=" * 50)
    print("  Test Cache Statistics")
    print("=" * 50)
    print(f"  Total entries:     {len(cache)}")
    print(f"  Passed:            {pass_count}")
    print(f"  Failed:            {fail_count}")
    print(f"  Unique test files: {len(unique_tests)}")
    print(f"  Avg dependencies:  {avg_deps:.1f}")
    print(f"  Newest entry:      {newest:.1f}h ago")
    print(f"  Oldest entry:      {oldest:.1f}h ago")
    print(f"  Cache file:        {CACHE_PATH}")

    if CACHE_PATH.exists():
        size_kb = CACHE_PATH.stat().st_size / 1024
        print(f"  Cache size:        {size_kb:.1f} KB")

    print("=" * 50)
    print()


def print_stats_json():
    """Print cache statistics as structured JSON."""
    cache = load_cache()
    now = time.time()
    pass_count = sum(1 for e in cache.values() if e.get("result") == "pass")
    fail_count = sum(1 for e in cache.values() if e.get("result") == "fail")
    unique_tests = set(e.get("test_file", "") for e in cache.values())
    unique_tests.discard("")
    dep_counts = [e.get("dep_count", 0) for e in cache.values()]
    avg_deps = sum(dep_counts) / len(dep_counts) if dep_counts else 0
    ages = [(now - e.get("timestamp", 0)) / 3600 for e in cache.values()]

    result = {
        "status": "pass",
        "total_entries": len(cache),
        "passed": pass_count,
        "failed": fail_count,
        "unique_test_files": len(unique_tests),
        "avg_dependencies": round(avg_deps, 1),
        "newest_hours": round(min(ages), 1) if ages else 0,
        "oldest_hours": round(max(ages), 1) if ages else 0,
        "cache_size_kb": round(CACHE_PATH.stat().st_size / 1024, 1) if CACHE_PATH.exists() else 0,
        "recommendation": f"Cache healthy: {pass_count} passed, {fail_count} failed" if cache else "Cache empty",
        "action_needed": False,
    }
    print(json.dumps(result, indent=2))


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    command = sys.argv[1]
    args = sys.argv[2:]

    if command == "filter":
        verbose = "--verbose" in args or "-v" in args
        test_files = [a for a in args if not a.startswith("-")]
        if not test_files:
            print("No test files to filter.")
            return 0
        need_run = filter_tests(test_files, verbose=verbose)
        # Output the files that need running (one per line for piping)
        for f in need_run:
            print(f)
        return 0

    elif command == "update":
        test_files = [a for a in args if not a.startswith("-")]
        result = "pass"  # default
        for a in args:
            if a.startswith("--result="):
                result = a.split("=", 1)[1]
        if not test_files:
            print("No test files to update.")
            return 0
        updated = update_cache(test_files, result=result)
        print(f"Cache updated: {updated} entries")
        return 0

    elif command == "invalidate":
        test_files = [a for a in args if not a.startswith("-")]
        if not test_files:
            print("No test files to invalidate.")
            return 0
        removed = invalidate_tests(test_files)
        print(f"Invalidated {removed} cache entries")
        return 0

    elif command == "purge":
        save_cache({})
        print("Cache purged.")
        return 0

    elif command == "gc":
        max_age = MAX_CACHE_AGE_HOURS
        for a in args:
            if a.startswith("--max-age="):
                try:
                    max_age = int(a.split("=", 1)[1])
                except ValueError:
                    pass
        before, after = gc_cache(max_age_hours=max_age)
        print(f"GC complete: {before} -> {after} entries (removed {before - after})")
        return 0

    elif command == "stats":
        if "--json" in args:
            print_stats_json()
        else:
            print_stats()
        return 0

    else:
        print(f"Unknown command: {command}")
        print("Commands: filter, update, invalidate, purge, gc, stats")
        return 1


if __name__ == "__main__":
    sys.exit(main())
