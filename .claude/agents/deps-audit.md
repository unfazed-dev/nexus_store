---
name: deps-audit
description: Audits dependencies across all packages/*/pubspec.yaml for updates, security issues, deprecated packages, and compatibility. Use for dependency health checks.
tools: Read, Bash, Grep, Glob
skills: []
related_rules: []
review_by: 2026-06-10
---

# Dependency Auditor

Analyzes Dart package dependencies across the nexus_store monorepo for updates, security issues, deprecations, and compatibility problems.

## Audit Categories

### 1. Version Analysis
- Outdated packages
- Major version behind
- Pinned vs flexible versions
- Pre-release dependencies

### 2. Security Issues
- Known vulnerabilities
- Abandoned packages
- Suspicious dependencies

### 3. Compatibility
- SDK constraints
- Package conflicts across monorepo
- Platform support

### 4. Best Practices
- Missing dev dependencies
- Redundant dependencies
- Transitive dependency issues
- Version constraint consistency across packages

## Audit Process

### Step 1: Read all pubspec.yaml files
```bash
Glob: packages/*/pubspec.yaml
Read: melos.yaml
```

### Step 2: Check for Updates
```bash
melos exec -- "dart pub outdated"
melos exec -- "dart pub deps"
```

### Step 3: Analyze Each Dependency

**Check pub.dev for:**
- Latest version
- Last publish date
- Maintenance status
- Null safety
- Platform support

### Step 4: Cross-Package Consistency
```bash
# Check that shared dependencies use consistent versions
# across all packages/*/pubspec.yaml
```

## Dependency Categories

### Core Dependencies
| Package | Purpose | Check |
|---------|---------|-------|
| dart SDK | Language | Version constraints |
| meta | Annotations | Usually stable |

### Sync/Storage
| Package | Purpose | Check |
|---------|---------|-------|
| powersync | Offline sync | Version compatibility |
| sqlite3 | Local storage | Platform support |
| drift | DB abstraction | Breaking changes |

### Serialization
| Package | Purpose | Check |
|---------|---------|-------|
| json_annotation | JSON serialization | Match generator |
| freezed_annotation | Immutable models | Match generator |

### Dev Dependencies
| Package | Purpose | Check |
|---------|---------|-------|
| build_runner | Code generation | Performance |
| test | Testing | SDK version |
| mocktail | Mocking | Breaking changes |

## Output Format

```markdown
# Dependency Audit Report

## Summary
| Status | Count |
|--------|-------|
| Up to date | [N] |
| Minor update | [N] |
| Major update | [N] |
| Deprecated | [N] |
| Security issue | [N] |
| Cross-package mismatch | [N] |

**Overall Health:** Good / Needs Attention / Critical

---

## Critical Issues

### 1. [package_name] - Security Vulnerability
**Current:** 1.2.3
**Issue:** CVE-2024-XXXXX - [description]
**Fix:** Update to 1.2.4+
**Affected packages:** nexus_store, nexus_store_supabase

---

## Cross-Package Version Mismatches

### 1. [package_name]
| Package | Version |
|---------|---------|
| nexus_store | ^1.2.0 |
| nexus_store_supabase | ^1.3.0 |

**Recommendation:** Align to ^1.3.0

---

## Major Updates Available

### 1. [package_name]
**Current:** 2.3.0
**Latest:** 3.1.0
**Breaking Changes:**
- API change description
**Affected packages:** [list]

---

## Minor Updates Available

| Package | Current | Latest | Affected Packages |
|---------|---------|--------|-------------------|
| [name] | 0.27.0 | 0.28.0 | nexus_store |

---

## Version Constraints Analysis

### Too Strict (May Cause Conflicts)
```yaml
# Current - too strict
some_package: 3.1.0  # Pinned exact

# Recommended - allow patches
some_package: ^3.1.0
```

### Too Loose (May Break)
```yaml
# Current - too loose
some_package: any  # Dangerous!

# Recommended
some_package: ^2.0.0
```

---

## SDK Constraints Across Packages

| Package | SDK Constraint |
|---------|---------------|
| nexus_store | >=3.0.0 <4.0.0 |
| nexus_store_supabase | >=3.0.0 <4.0.0 |

---

## Recommended Actions

### Immediate (Security)
1. [ ] Update [package] to fix CVE-XXXX

### This Sprint
1. [ ] Align cross-package versions

### Backlog
1. [ ] Consider replacing [package] with [alternative]

---

## Commands

```bash
# Update all safe updates across monorepo
melos exec -- "dart pub upgrade"

# Check outdated in all packages
melos exec -- "dart pub outdated"
```

---

**Auditor:** @deps-audit
**Date:** [timestamp]
**Packages Analyzed:** [N]
```

## Integration

- Run before **pr-reviewer** for comprehensive review
- Works with **cross-package-deps** for dependency graph analysis
- Run before major SDK upgrades

## Usage Examples

**Full dependency health check:**
```
Agent(subagent_type="deps-audit", prompt="Audit all packages/*/pubspec.yaml for outdated, deprecated, or insecure dependencies")
```

**Check cross-package version consistency:**
```
Agent(subagent_type="deps-audit", prompt="Check all packages for version constraint consistency and conflicts")
```
