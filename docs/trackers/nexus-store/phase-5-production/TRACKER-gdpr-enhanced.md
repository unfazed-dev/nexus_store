# TRACKER: Enhanced GDPR Compliance

## Status: PENDING

## Overview

Implement enhanced GDPR compliance features including data minimization (retention policies), consent tracking, and breach notification support. Extends the existing GDPR service.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-026, REQ-027, REQ-028, Task 25
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Minimization (REQ-026)

#### Data Models
- [ ] Create `RetentionPolicy` class
  - [ ] `field: String` - Field name to apply policy
  - [ ] `duration: Duration` - How long to retain
  - [ ] `action: RetentionAction` - What to do when expired
  - [ ] `condition: String?` - Optional condition expression

- [ ] Create `RetentionAction` enum
  - [ ] `nullify` - Set field to null
  - [ ] `anonymize` - Replace with anonymous value
  - [ ] `deleteRecord` - Delete entire record
  - [ ] `archive` - Move to archive store

#### Implementation
- [ ] Create `DataMinimizationService` class
  - [ ] Accept list of RetentionPolicy
  - [ ] Track record creation timestamps
  - [ ] Process expired fields/records

- [ ] Implement retention processor
  - [ ] `processRetention()` - Run retention checks
  - [ ] Identify expired items
  - [ ] Apply retention actions
  - [ ] Create audit log entries

- [ ] Add automatic scheduling
  - [ ] Configurable check interval
  - [ ] Background processing option
  - [ ] Manual trigger method

### Consent Tracking (REQ-027)

#### Data Models
- [ ] Create `ConsentRecord` class
  - [ ] `userId: String` - Subject identifier
  - [ ] `purposes: Map<String, ConsentStatus>` - Purpose → status
  - [ ] `history: List<ConsentEvent>` - Full history
  - [ ] `lastUpdated: DateTime`

- [ ] Create `ConsentStatus` class
  - [ ] `granted: bool`
  - [ ] `grantedAt: DateTime?`
  - [ ] `withdrawnAt: DateTime?`
  - [ ] `source: String?` - Where consent was given

- [ ] Create `ConsentEvent` class
  - [ ] `purpose: String`
  - [ ] `action: ConsentAction` (granted, withdrawn)
  - [ ] `timestamp: DateTime`
  - [ ] `source: String?`
  - [ ] `ipAddress: String?`

- [ ] Create `ConsentPurpose` predefined constants
  - [ ] `marketing`, `analytics`, `personalization`
  - [ ] `thirdPartySharing`, `profiling`
  - [ ] Allow custom purposes

#### Implementation
- [ ] Create `ConsentService` class
  - [ ] `recordConsent(userId, purposes, source)` - Grant consent
  - [ ] `withdrawConsent(userId, purposes)` - Revoke consent
  - [ ] `getConsent(userId)` - Get current consent status
  - [ ] `hasConsent(userId, purpose)` - Quick check
  - [ ] `getConsentHistory(userId)` - Full audit trail

- [ ] Implement consent storage
  - [ ] Store in backend via dedicated table/collection
  - [ ] Index by userId for fast lookup

- [ ] Integrate with audit logging
  - [ ] Log all consent changes
  - [ ] Include in audit exports

### Breach Notification (REQ-028)

#### Data Models
- [ ] Create `BreachReport` class
  - [ ] `id: String` - Unique breach identifier
  - [ ] `detectedAt: DateTime`
  - [ ] `affectedUsers: List<String>` - User IDs
  - [ ] `affectedDataCategories: Set<String>`
  - [ ] `description: String`
  - [ ] `timeline: List<BreachEvent>`

- [ ] Create `BreachEvent` class
  - [ ] `timestamp: DateTime`
  - [ ] `action: String`
  - [ ] `actor: String`
  - [ ] `notes: String?`

- [ ] Create `AffectedUserInfo` class
  - [ ] `userId: String`
  - [ ] `affectedFields: Set<String>`
  - [ ] `accessedAt: DateTime?`
  - [ ] `notified: bool`

#### Implementation
- [ ] Create `BreachService` class
  - [ ] `identifyAffectedUsers(query, timeRange)` - Find affected users
  - [ ] `generateBreachReport(affectedUsers)` - Create report
  - [ ] `recordBreachEvent(breachId, event)` - Log timeline
  - [ ] `getBreachReport(breachId)` - Retrieve report

- [ ] Implement affected user identification
  - [ ] Query audit logs for data access
  - [ ] Filter by time range
  - [ ] Aggregate by user

- [ ] Implement report generation
  - [ ] Aggregate affected data categories
  - [ ] Generate summary statistics
  - [ ] Export-ready format

### GdprConfig Updates
- [ ] Add `retentionPolicies` to GdprConfig
  - [ ] List of RetentionPolicy
  - [ ] Auto-processing configuration

- [ ] Add `consentTracking` to GdprConfig
  - [ ] Enable/disable consent features
  - [ ] Required purposes configuration

- [ ] Add `breachSupport` to GdprConfig
  - [ ] Enable/disable breach features
  - [ ] Notification webhooks

### GdprService Integration
- [ ] Add data minimization methods
  - [ ] `processRetention()`
  - [ ] `getRetentionStatus(userId)`

- [ ] Add consent methods
  - [ ] `recordConsent(...)`, `withdrawConsent(...)`
  - [ ] `getConsent(...)`, `hasConsent(...)`

- [ ] Add breach methods
  - [ ] `identifyAffectedUsers(...)`
  - [ ] `generateBreachReport(...)`

### Unit Tests
- [ ] `test/src/compliance/data_minimization_test.dart`
  - [ ] Retention policy applies correctly
  - [ ] Expired fields are nullified/anonymized
  - [ ] Audit log created for retention actions

- [ ] `test/src/compliance/consent_service_test.dart`
  - [ ] Consent recording works
  - [ ] Consent withdrawal works
  - [ ] History is maintained
  - [ ] hasConsent check is accurate

- [ ] `test/src/compliance/breach_service_test.dart`
  - [ ] Affected users identified correctly
  - [ ] Report generation includes all data
  - [ ] Timeline tracking works

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
