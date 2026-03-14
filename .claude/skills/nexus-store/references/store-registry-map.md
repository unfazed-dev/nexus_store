# Store Registry Map

All NexusStore declarations across both registries.

## StoreRegistry (Remote — PowerSync synced)

`lib/data/stores/store_registry.dart`

### Core

| Variable | Entity Type | Table |
|---|---|---|
| `profiles` | `Profile` | `core_profiles` |
| `userSettings` | `UserSettings` | `core_user_settings` |
| `appSettings` | `AppSetting` | `core_app_settings` |
| `userSelections` | `UserSelection` | `core_user_selections` |
| `surfacePreferences` | `SurfacePreference` | `core_surface_preferences` |
| `documents` | `Document` | `core_documents` |
| `legalDocuments` | `LegalDocument` | `core_legal_documents` |
| `legalAcceptances` | `LegalAcceptance` | `core_legal_acceptances` |

### Bookings & Scheduling

| Variable | Entity Type | Table |
|---|---|---|
| `bookings` | `Booking` | `customer_bookings` |
| `bookingStatusHistories` | `BookingStatusChange` | `customer_booking_status_changes` |
| `shifts` | `Shift` | `services_shifts` |

### Financial

| Variable | Entity Type | Table |
|---|---|---|
| `walletAccounts` | `WalletAccount` | `core_wallet_accounts` |
| `walletLedgerEntries` | `WalletLedgerEntry` | `core_wallet_ledger_entries` |
| `walletTopUps` | `WalletTopUp` | `core_wallet_top_ups` |
| `walletPurchases` | `WalletPurchase` | `core_wallet_purchases` |
| `walletPurchaseItems` | `WalletPurchaseItem` | `core_wallet_purchase_items` |
| `walletPurchaseReceipts` | `WalletPurchaseReceipt` | `core_wallet_purchase_receipts` |
| `walletServicePayments` | `WalletServicePayment` | `core_wallet_service_payments` |
| `expenses` | `Expense` | `services_expenses` |
| `receipts` | `Receipt` | `services_receipts` |
| `payslips` | `Payslip` | `services_payslips` |
| `payslipLineItems` | `PayslipLineItem` | `services_payslip_line_items` |
| `payslipDeductions` | `PayslipDeduction` | `services_payslip_deductions` |
| `payRates` | `PayRate` | `services_pay_rates` |
| `staffSuperannuations` | `StaffSuperannuation` | `services_superannuations` |

### Records & Notes

| Variable | Entity Type | Table |
|---|---|---|
| `journalEntries` | `JournalEntry` | `core_journal_entries` |
| `progressNotes` | `ProgressNote` | `services_progress_notes` |
| `travelEntries` | `TravelEntry` | `services_travel_entries` |
| `incidents` | `Incident` | `services_incidents` |
| `complaints` | `Complaint` | `services_complaints` |

### Staff & HR

| Variable | Entity Type | Table |
|---|---|---|
| `staffProfiles` | `StaffProfile` | `services_staff_profiles` |
| `staffContracts` | `StaffContract` | `services_staff_contracts` |
| `staffRegistrations` | `StaffRegistration` | `services_staff_registrations` |
| `staffOnboardingSteps` | `OnboardingStep` | `services_onboarding_steps` |
| `staffSlaAgreements` | `StaffSlaAgreement` | `services_staff_sla_agreements` |

### Compliance & Legal

| Variable | Entity Type | Table |
|---|---|---|
| `complianceRequirements` | `ComplianceRequirement` | `admin_compliance_requirements` |
| `staffComplianceRecords` | `StaffComplianceRecord` | `services_staff_compliance` |
| `customerComplianceRecords` | `CustomerComplianceRecord` | `customer_compliance` |
| `complianceAuditLog` | `ComplianceAuditEntry` | `admin_compliance_audit` |
| `slaTemplates` | `SlaTemplate` | `admin_sla_templates` |
| `slaAgreements` | `SlaAgreement` | `admin_sla_agreements` |

### Administration

| Variable | Entity Type | Table |
|---|---|---|
| `clmAssignments` | `ClmAssignment` | `admin_clm_assignments` |
| `delegations` | `AccountManager` | `admin_delegations` |
| `managerInvitations` | `ManagerInvitation` | `admin_manager_invitations` |
| `enrollments` | `Enrollment` | `admin_enrollments` |
| `customerOnboardingSteps` | `OnboardingStep` | `customer_onboarding_steps` |

### Training

| Variable | Entity Type | Table |
|---|---|---|
| `trainingPrograms` | `TrainingProgram` | `admin_training_programs` |
| `trainingModules` | `TrainingModule` | `admin_training_modules` |
| `trainingEnrollments` | `TrainingEnrollment` | `admin_training_enrollments` |
| `trainingCompletions` | `TrainingCompletion` | `admin_training_completions` |

## LocalStoreRegistry (Local — Drift/SQLite)

`lib/data/stores/local_store_registry.dart`

| Variable | Entity Type | Persistence |
|---|---|---|
| `deviceSettings` | `DeviceSettings` | Drift (SQLite) |
| `formDrafts` | `FormDraft` | Drift (SQLite) |
| `chatMessages` | `ChatMessage` | Drift (SQLite) |
| `syncOperations` | `SyncOperation` | Drift (SQLite) |

## Totals
- **Remote stores:** 46+
- **Local stores:** 4
- **Total:** 50+
