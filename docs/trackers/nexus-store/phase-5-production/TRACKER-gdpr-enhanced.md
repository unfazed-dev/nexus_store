# TRACKER: Enhanced GDPR Compliance

## Status: COMPLETE

## Overview

Implement enhanced GDPR compliance features including data minimization (retention policies), consent tracking, and breach notification support. Extends the existing GDPR service.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-026, REQ-027, REQ-028, Task 25
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Minimization (REQ-026)

#### Data Models
- [x] Create `RetentionPolicy` class
  - [x] `field: String` - Field name to apply policy
  - [x] `duration: Duration` - How long to retain
  - [x] `action: RetentionAction` - What to do when expired
  - [x] `condition: String?` - Optional condition expression

- [x] Create `RetentionAction` enum
  - [x] `nullify` - Set field to null
  - [x] `anonymize` - Replace with anonymous value
  - [x] `deleteRecord` - Delete entire record
  - [x] `archive` - Move to archive store

#### Implementation
- [x] Create `DataMinimizationService` class
  - [x] Accept list of RetentionPolicy
  - [x] Track record creation timestamps
  - [x] Process expired fields/records

- [x] Implement retention processor
  - [x] `processRetention()` - Run retention checks
  - [x] Identify expired items
  - [x] Apply retention actions
  - [x] Create audit log entries

- [x] Add automatic scheduling
  - [x] Configurable check interval
  - [x] Background processing option
  - [x] Manual trigger method

### Consent Tracking (REQ-027)

#### Data Models
- [x] Create `ConsentRecord` class
  - [x] `userId: String` - Subject identifier
  - [x] `purposes: Map<String, ConsentStatus>` - Purpose → status
  - [x] `history: List<ConsentEvent>` - Full history
  - [x] `lastUpdated: DateTime`

- [x] Create `ConsentStatus` class
  - [x] `granted: bool`
  - [x] `grantedAt: DateTime?`
  - [x] `withdrawnAt: DateTime?`
  - [x] `source: String?` - Where consent was given

- [x] Create `ConsentEvent` class
  - [x] `purpose: String`
  - [x] `action: ConsentAction` (granted, withdrawn)
  - [x] `timestamp: DateTime`
  - [x] `source: String?`
  - [x] `ipAddress: String?`

- [x] Create `ConsentPurpose` predefined constants
  - [x] `marketing`, `analytics`, `personalization`
  - [x] `thirdPartySharing`, `profiling`
  - [x] Allow custom purposes

#### Implementation
- [x] Create `ConsentService` class
  - [x] `recordConsent(userId, purposes, source)` - Grant consent
  - [x] `withdrawConsent(userId, purposes)` - Revoke consent
  - [x] `getConsent(userId)` - Get current consent status
  - [x] `hasConsent(userId, purpose)` - Quick check
  - [x] `getConsentHistory(userId)` - Full audit trail

- [x] Implement consent storage
  - [x] Store in backend via dedicated table/collection
  - [x] Index by userId for fast lookup

- [x] Integrate with audit logging
  - [x] Log all consent changes
  - [x] Include in audit exports

### Breach Notification (REQ-028)

#### Data Models
- [x] Create `BreachReport` class
  - [x] `id: String` - Unique breach identifier
  - [x] `detectedAt: DateTime`
  - [x] `affectedUsers: List<String>` - User IDs
  - [x] `affectedDataCategories: Set<String>`
  - [x] `description: String`
  - [x] `timeline: List<BreachEvent>`

- [x] Create `BreachEvent` class
  - [x] `timestamp: DateTime`
  - [x] `action: String`
  - [x] `actor: String`
  - [x] `notes: String?`

- [x] Create `AffectedUserInfo` class
  - [x] `userId: String`
  - [x] `affectedFields: Set<String>`
  - [x] `accessedAt: DateTime?`
  - [x] `notified: bool`

#### Implementation
- [x] Create `BreachService` class
  - [x] `identifyAffectedUsers(query, timeRange)` - Find affected users
  - [x] `generateBreachReport(affectedUsers)` - Create report
  - [x] `recordBreachEvent(breachId, event)` - Log timeline
  - [x] `getBreachReport(breachId)` - Retrieve report

- [x] Implement affected user identification
  - [x] Query audit logs for data access
  - [x] Filter by time range
  - [x] Aggregate by user

- [x] Implement report generation
  - [x] Aggregate affected data categories
  - [x] Generate summary statistics
  - [x] Export-ready format

### GdprConfig Updates
- [x] Add `retentionPolicies` to GdprConfig
  - [x] List of RetentionPolicy
  - [x] Auto-processing configuration

- [x] Add `consentTracking` to GdprConfig
  - [x] Enable/disable consent features
  - [x] Required purposes configuration

- [x] Add `breachSupport` to GdprConfig
  - [x] Enable/disable breach features
  - [x] Notification webhooks

### GdprService Integration
- [x] Add data minimization methods
  - [x] `processRetention()`
  - [x] `getRetentionStatus(userId)`

- [x] Add consent methods
  - [x] `recordConsent(...)`, `withdrawConsent(...)`
  - [x] `getConsent(...)`, `hasConsent(...)`

- [x] Add breach methods
  - [x] `identifyAffectedUsers(...)`
  - [x] `generateBreachReport(...)`

### Unit Tests
- [x] `test/src/compliance/data_minimization_test.dart`
  - [x] Retention policy applies correctly
  - [x] Expired fields are nullified/anonymized
  - [x] Audit log created for retention actions

- [x] `test/src/compliance/consent_service_test.dart`
  - [x] Consent recording works
  - [x] Consent withdrawal works
  - [x] History is maintained
  - [x] hasConsent check is accurate

- [x] `test/src/compliance/breach_service_test.dart`
  - [x] Affected users identified correctly
  - [x] Report generation includes all data
  - [x] Timeline tracking works

## Files

**Source Files:**
```
packages/nexus_store/lib/src/compliance/
├── data_minimization.dart     # DataMinimizationService
├── retention_policy.dart      # RetentionPolicy, RetentionAction
├── consent_service.dart       # ConsentService
├── consent_record.dart        # ConsentRecord, ConsentEvent
├── breach_service.dart        # BreachService
├── breach_report.dart         # BreachReport, AffectedUserInfo
└── gdpr_service.dart          # Update with new methods

packages/nexus_store/lib/src/config/
└── gdpr_config.dart           # Update with new options
```

**Test Files:**
```
packages/nexus_store/test/src/compliance/
├── data_minimization_test.dart
├── consent_service_test.dart
└── breach_service_test.dart
```

## Dependencies

- Audit logging (Task 12, complete)
- GDPR service (Task 13, complete)

## API Preview

```dart
// Configure GDPR with all features
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    gdpr: GdprConfig(
      // Data minimization
      retentionPolicies: [
        RetentionPolicy(
          field: 'ipAddress',
          duration: Duration(days: 30),
          action: RetentionAction.nullify,
        ),
        RetentionPolicy(
          field: 'loginHistory',
          duration: Duration(days: 90),
          action: RetentionAction.deleteRecord,
        ),
      ],
      autoProcessRetention: true,
      retentionCheckInterval: Duration(hours: 24),

      // Consent tracking
      consentTracking: true,
      requiredPurposes: {'analytics', 'personalization'},

      // Breach support
      breachSupport: true,
    ),
  ),
);

// Consent management
await store.gdpr!.recordConsent(
  userId: 'user-123',
  purposes: {'marketing', 'analytics'},
  source: 'signup-form',
);

final consent = await store.gdpr!.getConsent('user-123');
if (consent.purposes['marketing']?.granted ?? false) {
  sendMarketingEmail(user);
}

await store.gdpr!.withdrawConsent(
  userId: 'user-123',
  purposes: {'marketing'},
);

// Get full consent history (for audits)
final history = await store.gdpr!.getConsentHistory('user-123');

// Breach notification
final affectedUsers = await store.gdpr!.identifyAffectedUsers(
  query: Query<User>().where('sensitiveData', isNotNull: true),
  timeRange: DateTimeRange(start: breachStart, end: breachEnd),
);

final report = await store.gdpr!.generateBreachReport(
  affectedUsers: affectedUsers,
  description: 'Unauthorized access to user database',
);

print('Affected users: ${report.affectedUsers.length}');
print('Data categories: ${report.affectedDataCategories}');
// Export report for regulatory notification

// Manual retention processing
await store.gdpr!.processRetention();
```

## Notes

- Data minimization should run in background to not block UI
- Consent must be granular (per-purpose, not all-or-nothing)
- Breach reports must be exportable for regulatory submission
- All GDPR actions must be audit logged
- Consider adding DPIA (Data Protection Impact Assessment) support
- Retention processing should handle large datasets efficiently
- Consent UI is application-specific; this provides the backend
- Consider integration with consent management platforms (OneTrust, etc.)
