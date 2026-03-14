# State Lifecycle Template

Ready-to-use state diagrams for documenting entity lifecycles and state machines.

## Entity Lifecycle (Booking Example)

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
stateDiagram-v2
    accTitle: Booking Lifecycle
    accDescr: Shows the 8-status booking lifecycle from requested through to paid, including cancellation paths.

    [*] --> Requested
    Requested --> Confirmed : CLM assigns staff
    Requested --> Cancelled : Customer cancels

    Confirmed --> Rescheduled : Time changed
    Confirmed --> InProgress : Auto-transition (cron)
    Confirmed --> Cancelled : CLM cancels

    Rescheduled --> Confirmed : CLM re-confirms
    Rescheduled --> Cancelled : CLM cancels

    InProgress --> Completed : Service finished
    InProgress --> Cancelled : Emergency cancel

    Completed --> Invoiced : Invoice generated
    Invoiced --> Paid : Payment received
    Paid --> [*]
    Cancelled --> [*]

    note right of Requested : Customer submits\nservice request
    note right of InProgress : Auto-transitions via\nDB cron every 5 min
    note right of Rescheduled : Original times stored in\noriginal_start_time/end_time
    note left of Cancelled : Can cancel from any\npre-completion state
```

## Nested Composite States

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
stateDiagram-v2
    accTitle: Invoice Processing Lifecycle
    accDescr: Invoice states with nested active processing substates.

    [*] --> Draft

    state Active {
        [*] --> Pending
        Pending --> UnderReview : Submit for review
        UnderReview --> Approved : CLM approves
        UnderReview --> Disputed : Customer disputes
        Disputed --> UnderReview : Resubmit
        Approved --> [*]
    }

    Draft --> Active : Finalize invoice
    Active --> Paid : Payment received
    Active --> Voided : Admin voids
    Draft --> Voided : Discard draft

    Paid --> [*]
    Voided --> [*]

    note right of Draft : Auto-generated from\ncompleted booking
    note right of Active : Multiple review cycles\npossible
```

## Choice Nodes (Conditional Routing)

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
stateDiagram-v2
    accTitle: Fund Source Resolution
    accDescr: Determines payment routing based on funding type using choice nodes.

    [*] --> CheckFunding
    state check_type <<choice>>
    CheckFunding --> check_type

    check_type --> KinlyWallet : fundingType == null
    check_type --> NdisSelfManaged : fundingType == self
    check_type --> NdisPlanManaged : fundingType == plan
    check_type --> NdisAgencyManaged : fundingType == agency

    KinlyWallet --> ProcessPayment
    NdisSelfManaged --> ProcessPayment
    NdisPlanManaged --> ExternalClaim
    NdisAgencyManaged --> ExternalClaim

    ProcessPayment --> [*]
    ExternalClaim --> [*]
```

## Fork/Join (Parallel Transitions)

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
stateDiagram-v2
    accTitle: Booking Completion Fork
    accDescr: Parallel processing after booking completion — invoice generation and notification happen simultaneously.

    [*] --> BookingCompleted

    state fork_state <<fork>>
    BookingCompleted --> fork_state

    fork_state --> GenerateInvoice
    fork_state --> SendNotification
    fork_state --> UpdateAnalytics

    GenerateInvoice --> InvoiceReady
    SendNotification --> NotificationSent
    UpdateAnalytics --> MetricsUpdated

    state join_state <<join>>
    InvoiceReady --> join_state
    NotificationSent --> join_state
    MetricsUpdated --> join_state

    join_state --> AllComplete
    AllComplete --> [*]
```

## Concurrent Regions

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#6366f1',
    'primaryTextColor': '#ffffff',
    'primaryBorderColor': '#4f46e5',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#22c55e',
    'lineColor': '#475569',
    'textColor': '#1e293b',
    'fontSize': '14px'
  }
}}%%
stateDiagram-v2
    accTitle: Shift Management Concurrent States
    accDescr: A shift has concurrent regions for time tracking and task tracking that operate independently.

    [*] --> ShiftActive

    state ShiftActive {
        state "Time Tracking" as TimeTracking {
            [*] --> ClockIn
            ClockIn --> OnBreak : Start break
            OnBreak --> ClockIn : End break
            ClockIn --> ClockOut : End shift
        }
        --
        state "Task Tracking" as TaskTracking {
            [*] --> Assigned
            Assigned --> InProgress : Start task
            InProgress --> Completed : Finish task
            Completed --> Assigned : Next task
        }
    }

    ShiftActive --> ShiftEnded : All tasks done + clocked out
    ShiftEnded --> [*]
```

## Usage Instructions

1. Copy the relevant lifecycle template
2. Rename states to match your entity
3. Add/remove transitions as needed
4. Include `note` annotations for important business rules
5. Test in [Mermaid Live Editor](https://mermaid.live/)

## State Diagram Syntax Reference

| Feature | Syntax | Example |
|---------|--------|---------|
| State | `StateName` | `Requested` |
| Transition | `A --> B : label` | `Draft --> Active : Submit` |
| Start | `[*] --> A` | `[*] --> Draft` |
| End | `A --> [*]` | `Paid --> [*]` |
| Note | `note right of A : text` | `note right of Draft : Auto-created` |
| Nested | `state Parent { ... }` | See composite example |
| Choice | `state name <<choice>>` | See choice example |
| Fork | `state name <<fork>>` | See fork example |
| Join | `state name <<join>>` | See join example |
| Concurrent | `--` inside state | See concurrent example |

## Tips

- Every state diagram MUST show failure/cancellation transitions (per style guide)
- Use `\n` for multi-line notes
- Nest states to reduce visual complexity for large lifecycles
- Use choice nodes instead of complex diamond flowcharts for conditional routing
- Fork/join is ideal for showing parallel async operations
