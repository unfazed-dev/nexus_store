# Package Environment Rules

## No Envied
- This is a library package — DO NOT use envied or `.env` files
- No static globals for configuration

## Configuration Pattern
- All configuration is provided via constructor injection
- Backend URLs, API keys, and credentials are passed by the consuming app
- Default values only for non-sensitive, non-environment-specific settings

## Test Configuration
- Use test helpers and fixtures, not `.env` files
- In-memory backends for unit tests
- Test doubles for external services

## CI/CD
- GitHub Actions for CI/CD
- Melos handles multi-package orchestration in CI
- `melos run analyze` and `melos run test:dart` in CI pipeline

## Enforcement
- **Manual only:** Configuration pattern adherence is enforced by code review
- **AGENTS.md lines:**
  - "DO NOT use envied or `.env` files -> this is a library package, use constructor injection"
  - "DO NOT use static globals for configuration -> pass config via constructors"
