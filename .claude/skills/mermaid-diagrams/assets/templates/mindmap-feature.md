# Mindmap Template

Ready-to-use mindmaps for documenting feature coverage, system structure, and concept hierarchies.

## Portal Structure

```mermaid
mindmap
    root((NexusStore))
        Customer Portal
            Bookings
                Request Service
                View Schedule
                Track Status
            Wallet
                Balance
                Top Up
                Transaction History
            Profile
                Preferences
                Addresses
                Documents
        Services Hub
            Assignments
                View Bookings
                Accept/Decline
                Check-in/out
            Availability
                Weekly Schedule
                Time Off
                Service Areas
            Earnings
                Timesheets
                Payment History
        Administration
            User Management
                Customers
                Contractors
                CLMs
            Compliance
                Documents
                Qualifications
                Background Checks
            Billing
                Invoices
                Credit Notes
                Reports
```

## GenUI Entity Provider Coverage

```mermaid
mindmap
    root((GenUI Entities))
        Booking
            BookingDataProvider
            BookingCatalog
            BookingSchemas
            MCQ Fields
                Service Type
                Date/Time
                Location
                Special Requirements
        Invoice
            InvoiceDataProvider
            InvoiceCatalog
            InvoiceSchemas
            MCQ Fields
                Invoice Type
                Line Items
                Funding Source
        Profile
            ProfileDataProvider
            ProfileCatalog
            ProfileSchemas
            MCQ Fields
                Name
                Contact
                Preferences
        Journal
            JournalDataProvider
            JournalCatalog
            JournalSchemas
            MCQ Fields
                Entry Type
                Content
                Attachments
```

## Feature Dependency Map

```mermaid
mindmap
    root((Kinly Wallet))
        Data Layer
            PowerSync Tables
                wallet_accounts
                wallet_transactions
                credit_notes
            NexusStore Providers
                WalletStoreProvider
                TransactionStoreProvider
            Repositories
                WalletRepository
                TransactionRepository
        Service Layer
            WalletService
                getBalance
                topUp
                deduct
            InvoiceService
                generateInvoice
                processPayment
            NdisPriceValidatorService
                validateRate
                lookupTier
        UI Layer
            Views
                WalletDashboardView
                TransactionListView
                TopUpView
            ViewModels
                WalletDashboardViewModel
                TransactionListViewModel
            Widgets
                BalanceCard
                TransactionTile
                TopUpForm
```

## Technology Stack

```mermaid
mindmap
    root((Tech Stack))
        Frontend
            Flutter 3.35+
            Dart 3.9+
            Stacked MVVM
            GenUI
                genui_claude
                a2ui_claude
        Backend
            Supabase
                Auth
                Database
                Storage
                Edge Functions
            PowerSync
                Sync Rules
                CRUD Queue
        Infrastructure
            Firebase
                Cloud Messaging
                Analytics
            Shorebird
                OTA Updates
            Sentry
                Error Tracking
```

## Sprint Feature Breakdown

```mermaid
mindmap
    root((Sprint 12))
        Must Have
            Booking Rescheduling
            Invoice PDF Export
            Push Notifications
        Should Have
            Contractor Ratings
            Service Categories Filter
            Wallet Auto Top-up
        Could Have
            Dark Mode
            Export Reports CSV
        Won't Have
            Video Consultations
            Multi-language Support
```

## Usage Instructions

1. Copy the relevant mindmap template
2. Update the root node with your topic
3. Modify branches using indentation (spaces, not tabs)
4. Test in [Mermaid Live Editor](https://mermaid.live/)

## Mindmap Syntax Reference

| Feature | Syntax | Example |
|---------|--------|---------|
| Root (rounded) | `root((Text))` | `root((System))` |
| Root (square) | `root[Text]` | `root[Features]` |
| Root (bang) | `root)Text(` | `root)Ideas(` |
| Branch | Indented text | `    Branch Name` |
| Sub-branch | Deeper indent | `        Sub Item` |
| Icons | `::icon(fa fa-name)` | `::icon(fa fa-book)` |

## Node Shapes

| Shape | Syntax | Visual |
|-------|--------|--------|
| Default | `Text` | Rounded rectangle |
| Square | `[Text]` | Rectangle |
| Rounded | `(Text)` | Rounded |
| Circle | `((Text))` | Circle |
| Bang | `)Text(` | Burst shape |
| Cloud | `)Text(` | Cloud shape |
| Hexagon | `{{Text}}` | Hexagon |

## Tips

- Mindmaps do NOT support theme init blocks — styling is automatic
- Use indentation (2+ spaces) to create hierarchy — tabs may not work
- Keep labels short — long text wraps poorly in mindmap nodes
- Limit depth to 4 levels for readability
- Use for brainstorming, feature maps, and structural overviews
- Not suitable for showing flow/sequence — use flowchart or sequence diagrams instead
