# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in nexus_store, please report it responsibly.

### How to Report

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Email security concerns to: **security@unfazed.dev** (or create a private security advisory on GitHub)
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours of your report
- **Initial Assessment**: Within 7 days
- **Resolution Timeline**: Depends on severity
  - Critical: 24-72 hours
  - High: 1-2 weeks
  - Medium: 2-4 weeks
  - Low: Next release cycle

### Security Features

nexus_store includes several security features for production use:

#### Encryption

- **Field-level encryption**: AES-256-GCM for sensitive fields (SSN, credit cards, etc.)
- **Database encryption**: SQLCipher support for full database encryption
- **Key derivation**: PBKDF2 with 310,000 iterations (OWASP 2023 standard)
- **Secure random**: All cryptographic operations use `Random.secure()`

#### Compliance

- **HIPAA audit logging**: Hash-chained tamper detection for audit trails
- **GDPR compliance**: Data erasure (Article 17), portability (Article 20), access (Article 15)
- **Breach detection**: Automatic detection and reporting mechanisms

#### Best Practices

When using nexus_store in production:

1. **Key Storage**: Always use platform secure storage (iOS Keychain, Android Keystore)
   ```dart
   // Use SecureSaltStorage from nexus_store_flutter_widgets
   final saltStorage = SecureSaltStorage();
   ```

2. **Never Hardcode Keys**: Use environment variables or secure storage
   ```dart
   // Bad
   final key = 'hardcoded-key-12345';

   // Good
   final key = await secureStorage.read(key: 'encryption_key');
   ```

3. **Rotate Keys Regularly**: Use versioned encryption
   ```dart
   final config = EncryptionConfig.fieldLevel(
     encryptedFields: {'ssn'},
     keyProvider: keyProvider,
     version: 'v2',  // Increment on rotation
   );
   ```

4. **Enable Audit Logging**: For compliance-sensitive applications
   ```dart
   final store = NexusStore<User, String>(
     backend: backend,
     auditService: HipaaAuditService(storage: auditStorage),
   );
   ```

## Security Advisories

Security advisories will be published on:
- GitHub Security Advisories
- Package CHANGELOG.md
- Direct notification to affected users (when possible)

## Scope

This security policy applies to:
- `nexus_store` (core package)
- `nexus_store_flutter_widgets`
- All adapter packages (`nexus_store_*_adapter`)
- All binding packages (`nexus_store_*_binding`)
- All generator packages (`nexus_store_*_generator`)

## Recognition

We appreciate responsible disclosure and will acknowledge security researchers in our release notes (unless you prefer to remain anonymous).
