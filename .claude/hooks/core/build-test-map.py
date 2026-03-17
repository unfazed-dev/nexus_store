#!/usr/bin/env python3
# review_by: 2026-09-10
"""
Build a source-to-test mapping index for the NexusStore monorepo.

Scans all *_test.dart files in each package for package imports and builds
a reverse index mapping each source file to the test files that depend on it.
Also applies convention-based path rules for the monorepo package structure.

Output: .claude/test-history/test-map.json (combined) and per-package maps.

Usage:
    python3 .claude/hooks/core/build-test-map.py [--stats] [--verbose] [--package=xxx]

I/O:
    Stdin:  none
    Stdout: progress/stats output; summary line on completion
    Output: .claude/test-history/test-map.json (JSON index of source->test mappings)
    Exit:   0 always

Dependencies:
    None (stdlib only; reads packages/*/lib/ and packages/*/test/ directories)
"""
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

# Project root: navigate from .claude/hooks/core/ up three levels
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
PACKAGES_DIR = PROJECT_ROOT / "packages"
OUTPUT_PATH = PROJECT_ROOT / ".claude" / "test-history" / "test-map.json"

# All known NexusStore packages for import detection
NEXUS_PACKAGES = [
    "nexus_store",
    "nexus_store_drift_adapter",
    "nexus_store_powersync_adapter",
    "nexus_store_supabase_adapter",
    "nexus_store_brick_adapter",
    "nexus_store_crdt_adapter",
    "nexus_store_bloc_binding",
    "nexus_store_riverpod_binding",
    "nexus_store_riverpod_generator",
    "nexus_store_signals_binding",
    "nexus_store_flutter_widgets",
    "nexus_store_generator",
    "nexus_store_entity_generator",
]

# Convention-based mapping rules for monorepo packages.
# Pattern is relative to package dir. Templates use {0}, {1} for capture groups.
CONVENTION_RULES = [
    # lib/src/foo.dart -> test/src/foo_test.dart
    (
        r"lib/src/(.+)\.dart",
        [
            "test/src/{0}_test.dart",
            "test/{0}_test.dart",
        ],
    ),
    # lib/src/subdir/foo.dart -> test/src/subdir/foo_test.dart
    (
        r"lib/src/(.+)/(.+)\.dart",
        [
            "test/src/{0}/{1}_test.dart",
            "test/{0}/{1}_test.dart",
            "test/unit/{0}/{1}_test.dart",
        ],
    ),
    # lib/foo.dart (barrel or top-level) -> test/foo_test.dart
    (
        r"lib/(.+)\.dart",
        [
            "test/{0}_test.dart",
        ],
    ),
]


def find_test_files(package_dir):
    """Find all *_test.dart files under a package's test/ directory."""
    test_dir = package_dir / "test"
    if not test_dir.exists():
        return []
    return sorted(test_dir.rglob("*_test.dart"))


def extract_package_imports(test_file, package_name):
    """Extract package imports from a test file (imports of this package or sibling nexus packages)."""
    imports = []
    try:
        with open(test_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("//"):
                    continue
                if line.startswith("import"):
                    # Match imports of this package
                    match = re.search(rf"'package:{re.escape(package_name)}/(.+)'", line)
                    if match:
                        imports.append(f"lib/{match.group(1)}")
                    # Also match cross-package nexus imports
                    for pkg in NEXUS_PACKAGES:
                        if pkg == package_name:
                            continue
                        match = re.search(rf"'package:{re.escape(pkg)}/(.+)'", line)
                        if match:
                            imports.append(f"__cross__/{pkg}/lib/{match.group(1)}")
                elif line.startswith("part") or line.startswith("export"):
                    match = re.search(rf"'package:{re.escape(package_name)}/(.+)'", line)
                    if match:
                        imports.append(f"lib/{match.group(1)}")
                # Stop scanning past imports
                elif line and not line.startswith("library") and not line.startswith("@"):
                    if re.match(r"^(class |void |Future |final |const |var |typedef |enum |mixin |extension |sealed )", line):
                        break
    except (OSError, UnicodeDecodeError):
        pass
    return imports


def apply_convention_rules(source_file):
    """Apply convention-based mapping rules to find candidate test files."""
    candidates = []
    for pattern, templates in CONVENTION_RULES:
        match = re.match(pattern, source_file)
        if match:
            groups = match.groups()
            for template in templates:
                try:
                    candidate = template.format(*groups)
                    candidates.append(candidate)
                except (IndexError, KeyError):
                    continue
    return candidates


def build_package_map(package_name, package_dir, verbose=False):
    """Build source-to-test mapping for a single package."""
    test_files = find_test_files(package_dir)
    if verbose:
        print(f"  [{package_name}] Found {len(test_files)} test files")

    # Phase 1: Import-based reverse index
    import_index = defaultdict(set)
    for test_file in test_files:
        rel_test = str(test_file.relative_to(package_dir))
        imports = extract_package_imports(test_file, package_name)
        for imp in imports:
            if imp.startswith("__cross__/"):
                # Cross-package import: store as packages/<pkg>/<path>
                parts = imp.split("/", 2)  # __cross__/<pkg>/lib/...
                cross_key = f"packages/{parts[1]}/{parts[2]}"
                import_index[cross_key].add(f"packages/{package_name}/{rel_test}")
            else:
                import_index[imp].add(rel_test)
        if verbose and imports:
            print(f"    {rel_test}: {len(imports)} imports")

    # Phase 2: Convention-based augmentation
    lib_root = package_dir / "lib"
    if lib_root.exists():
        for source_file in lib_root.rglob("*.dart"):
            rel_source = str(source_file.relative_to(package_dir))
            # Skip generated files
            if rel_source.endswith(".g.dart") or rel_source.endswith(".freezed.dart"):
                continue
            candidates = apply_convention_rules(rel_source)
            for candidate in candidates:
                candidate_path = package_dir / candidate
                if candidate_path.exists():
                    import_index[rel_source].add(candidate)

    # Convert sets to sorted lists
    return {k: sorted(v) for k, v in import_index.items()}, len(test_files)


def build_map(target_package=None, verbose=False):
    """Build the complete source-to-test mapping across all packages."""
    all_mappings = {}
    total_test_count = 0
    cross_package_mappings = defaultdict(set)

    packages = []
    if target_package:
        pkg_dir = PACKAGES_DIR / target_package
        if pkg_dir.is_dir():
            packages = [(target_package, pkg_dir)]
        else:
            print(f"Package not found: {target_package}")
            return {"built_at": datetime.now().isoformat(), "source_count": 0, "test_count": 0, "mappings": {}, "packages": {}}
    else:
        for pkg_dir in sorted(PACKAGES_DIR.iterdir()):
            if pkg_dir.is_dir() and (pkg_dir / "pubspec.yaml").is_file():
                packages.append((pkg_dir.name, pkg_dir))

    package_stats = {}
    for pkg_name, pkg_dir in packages:
        mappings, test_count = build_package_map(pkg_name, pkg_dir, verbose=verbose)
        total_test_count += test_count

        # Separate cross-package mappings
        pkg_mappings = {}
        for key, tests in mappings.items():
            full_key = f"packages/{pkg_name}/{key}" if not key.startswith("packages/") else key
            all_mappings[full_key] = tests
            if not key.startswith("packages/"):
                pkg_mappings[key] = tests

        package_stats[pkg_name] = {
            "source_count": len(pkg_mappings),
            "test_count": test_count,
        }

    return {
        "built_at": datetime.now().isoformat(),
        "source_count": len(all_mappings),
        "test_count": total_test_count,
        "mappings": all_mappings,
        "packages": package_stats,
    }


def print_stats(test_map):
    """Print mapping statistics."""
    mappings = test_map["mappings"]
    packages = test_map.get("packages", {})

    sources_with_tests = len(mappings)
    total_test_links = sum(len(v) for v in mappings.values())

    all_test_files = set()
    for tests in mappings.values():
        all_test_files.update(tests)

    print(f"\n{'=' * 60}")
    print(f"  Test Map Statistics")
    print(f"{'=' * 60}")
    print(f"  Built:               {test_map['built_at']}")
    print(f"  Source files mapped:  {sources_with_tests}")
    print(f"  Test files indexed:   {test_map['test_count']}")
    print(f"  Test files linked:    {len(all_test_files)}")
    print(f"  Total mappings:       {total_test_links}")
    print(f"  Packages:             {len(packages)}")
    print(f"{'=' * 60}")

    if packages:
        print(f"\n  Per-package breakdown:")
        for pkg_name, stats in sorted(packages.items()):
            print(f"    {pkg_name}: {stats['source_count']} sources, {stats['test_count']} tests")

    # Top 10 most-tested source files
    top_sources = sorted(mappings.items(), key=lambda x: len(x[1]), reverse=True)[:10]
    if top_sources:
        print(f"\n  Top 10 most-tested source files:")
        for source, tests in top_sources:
            print(f"    {len(tests):3d} tests <- {source}")

    print()


def main():
    args = sys.argv[1:]
    verbose = "--verbose" in args or "-v" in args
    show_stats = "--stats" in args

    target_package = None
    for arg in args:
        if arg.startswith("--package="):
            target_package = arg.split("=", 1)[1]

    if verbose:
        print(f"Project root: {PROJECT_ROOT}")
        print(f"Packages dir: {PACKAGES_DIR}")
        print(f"Output: {OUTPUT_PATH}")

    test_map = build_map(target_package=target_package, verbose=verbose)

    # Ensure output directory exists
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    # Write map
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(test_map, f, indent=2)

    print(f"Test map built: {test_map['source_count']} source files -> {test_map['test_count']} test files")
    print(f"Saved to: {OUTPUT_PATH}")

    if show_stats:
        print_stats(test_map)


if __name__ == "__main__":
    main()
