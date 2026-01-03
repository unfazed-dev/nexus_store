# Publishing Guide

This guide describes how to publish nexus_store packages to pub.dev.

## Prerequisites

1. Ensure you have a verified pub.dev account
2. Run `dart pub login` to authenticate

## Pre-publish Checklist

### 1. Run All Validations

```bash
# Run analyzer across all packages
melos exec -- dart analyze

# Run all tests
melos exec -- dart test

# Format all code
melos exec -- dart format .
```

### 2. Update Versions

Update version numbers in each package's `pubspec.yaml` following [Semantic Versioning](https://semver.org/):
- PATCH (0.1.x): Bug fixes
- MINOR (0.x.0): New features (backward compatible)
- MAJOR (x.0.0): Breaking changes

### 3. Update CHANGELOGs

Add release notes to each package's `CHANGELOG.md`.

## Converting Path Dependencies to Hosted

**Important**: Before publishing, you must convert path dependencies to hosted versions.

### Packages with Internal Dependencies

The following packages depend on `nexus_store` core:

| Package | Dependencies |
|---------|--------------|
| `nexus_store_flutter_widgets` | nexus_store |
| `nexus_store_powersync_adapter` | nexus_store |
| `nexus_store_supabase_adapter` | nexus_store |
| `nexus_store_drift_adapter` | nexus_store |
| `nexus_store_brick_adapter` | nexus_store |
| `nexus_store_crdt_adapter` | nexus_store |
| `nexus_store_bloc_binding` | nexus_store |
| `nexus_store_riverpod_binding` | nexus_store |
| `nexus_store_signals_binding` | nexus_store |
| `nexus_store_generator` | nexus_store |
| `nexus_store_entity_generator` | nexus_store |
| `nexus_store_riverpod_generator` | nexus_store, nexus_store_riverpod_binding |

### Conversion Steps

#### Step 1: Publish Core Package First

```bash
cd packages/nexus_store
dart pub publish
```

#### Step 2: Update Dependent Packages

For each dependent package, update `pubspec.yaml`:

**Before (development):**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
```

**After (publishing):**
```yaml
dependencies:
  nexus_store: ^0.1.0
```

#### Step 3: Remove pubspec_overrides.yaml

The `pubspec_overrides.yaml` files are for local development only. They should be:
1. Listed in `.gitignore` (already done)
2. Not included in published packages

#### Step 4: Verify and Publish

```bash
# Dry run to verify
dart pub publish --dry-run

# If successful, publish
dart pub publish
```

## Publishing Order

Publish packages in this order to respect dependencies:

1. **Core (no dependencies)**
   - `nexus_store`

2. **Adapters (depend on core)**
   - `nexus_store_powersync_adapter`
   - `nexus_store_supabase_adapter`
   - `nexus_store_drift_adapter`
   - `nexus_store_brick_adapter`
   - `nexus_store_crdt_adapter`

3. **Bindings (depend on core)**
   - `nexus_store_bloc_binding`
   - `nexus_store_riverpod_binding`
   - `nexus_store_signals_binding`

4. **Flutter (depends on core)**
   - `nexus_store_flutter_widgets`

5. **Generators (depend on core and bindings)**
   - `nexus_store_generator`
   - `nexus_store_entity_generator`
   - `nexus_store_riverpod_generator`

## Automated Publishing Script

Create a script for automated publishing:

```bash
#!/bin/bash
# publish_all.sh

set -e

PACKAGES=(
  "nexus_store"
  "nexus_store_powersync_adapter"
  "nexus_store_supabase_adapter"
  "nexus_store_drift_adapter"
  "nexus_store_brick_adapter"
  "nexus_store_crdt_adapter"
  "nexus_store_bloc_binding"
  "nexus_store_riverpod_binding"
  "nexus_store_signals_binding"
  "nexus_store_flutter_widgets"
  "nexus_store_generator"
  "nexus_store_entity_generator"
  "nexus_store_riverpod_generator"
)

for pkg in "${PACKAGES[@]}"; do
  echo "Publishing $pkg..."
  cd packages/$pkg
  dart pub publish --force
  cd ../..
  echo "Published $pkg"
  sleep 5  # Wait for pub.dev to index
done

echo "All packages published!"
```

## Reverting to Development Mode

After publishing, revert to path dependencies for local development:

```bash
# Run melos bootstrap to restore local overrides
melos bootstrap
```

The `pubspec_overrides.yaml` files will restore path dependencies for development.

## Troubleshooting

### "Package has issues"

Run `dart pub publish --dry-run` to see specific issues.

### "Version already exists"

Increment the version number in `pubspec.yaml`.

### "Missing LICENSE"

Ensure LICENSE file exists in package root (already added - BSD-3 Clause).

### "Path dependency not allowed"

Convert path dependencies to hosted versions as described above.
