# Publishing & Versioning Rules

## Versioning
- Use Melos for versioning: `melos version`
- Follow semantic versioning (SemVer) strictly
- Breaking changes require a major version bump
- New features with backward compatibility: minor version bump
- Bug fixes and patches: patch version bump

## Changelog
- Use Keep a Changelog format (https://keepachangelog.com)
- Update `CHANGELOG.md` with every PR
- Sections: Added, Changed, Deprecated, Removed, Fixed, Security
- Each entry references the PR or issue number

## Publishing Checklist
- All tests pass: `melos run test:dart && melos run test:flutter`
- Static analysis clean: `melos run analyze`
- Format check passes: `melos run format:check`
- CHANGELOG.md updated
- Version bumped appropriately
- README.md reflects current API
- Breaking changes documented with migration guide
- `dart pub publish --dry-run` succeeds for each package

## Package Publishing Order
- Publish core (`nexus_store`) first
- Then adapters (no inter-adapter dependencies)
- Then bindings
- Then generators
- Then `nexus_store_flutter_widgets`

## Enforcement
- **Manual only:** Versioning and changelog conventions are enforced by code review
- **AGENTS.md lines:**
  - "DO NOT publish without updating CHANGELOG.md"
  - "DO NOT make breaking changes without a major version bump"
  - "DO NOT publish packages out of dependency order -> publish core first"
