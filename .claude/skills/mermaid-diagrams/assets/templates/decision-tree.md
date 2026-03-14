# Decision Tree Template

Ready-to-use flowcharts for documenting decision logic and workflows.

## Basic Decision Tree

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
flowchart TD
    accTitle: Basic Decision Tree
    accDescr: Simple branching decision tree with three questions leading to four possible results.

    Start([Start]) --> Q1{First Question?}

    Q1 -->|Yes| Q2{Second Question?}
    Q1 -->|No| R1[Result 1]

    Q2 -->|Yes| R2[Result 2]
    Q2 -->|No| Q3{Third Question?}

    Q3 -->|Yes| R3[Result 3]
    Q3 -->|No| R4[Result 4]

    R1 --> End([End])
    R2 --> End
    R3 --> End
    R4 --> End

    classDef start fill:#6366f1,stroke:#4f46e5,color:#fff,stroke-width:2px
    classDef process fill:#3b82f6,stroke:#2563eb,color:#fff,stroke-width:2px
    classDef success fill:#22c55e,stroke:#16a34a,color:#fff,stroke-width:2px
    classDef warning fill:#f59e0b,stroke:#d97706,color:#fff,stroke-width:2px
    classDef error fill:#ef4444,stroke:#dc2626,color:#fff,stroke-width:2px
    classDef info fill:#8b5cf6,stroke:#7c3aed,color:#fff,stroke-width:2px
    classDef neutral fill:#64748b,stroke:#475569,color:#fff,stroke-width:2px
    classDef critical fill:#f43f5e,stroke:#e11d48,color:#fff,stroke-width:2px

    class Start,End start
    class R2,R3 success
    class R1,R4 neutral
```

## Troubleshooting Flowchart

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
flowchart TD
    accTitle: Troubleshooting Flowchart
    accDescr: Decision flow for diagnosing and resolving reported problems through reproducibility checks and knowledge base lookups.

    Start([Problem Reported]) --> Check1{Is it<br/>reproducible?}

    Check1 -->|No| Log1[Log incident<br/>Monitor]
    Check1 -->|Yes| Check2{Error message<br/>visible?}

    Check2 -->|Yes| Lookup[Search error<br/>in knowledge base]
    Check2 -->|No| Check3{Recent<br/>changes?}

    Lookup --> Found{Solution<br/>found?}
    Found -->|Yes| Apply[Apply fix]
    Found -->|No| Check3

    Check3 -->|Yes| Rollback[Rollback<br/>recent changes]
    Check3 -->|No| Escalate[Escalate to<br/>senior engineer]

    Rollback --> Verify{Issue<br/>resolved?}
    Apply --> Verify

    Verify -->|Yes| Document[Document<br/>solution]
    Verify -->|No| Escalate

    Document --> End([Close ticket])
    Log1 --> End
    Escalate --> End

    classDef start fill:#6366f1,stroke:#4f46e5,color:#fff,stroke-width:2px
    classDef success fill:#22c55e,stroke:#16a34a,color:#fff,stroke-width:2px
    classDef warning fill:#f59e0b,stroke:#d97706,color:#fff,stroke-width:2px
    classDef error fill:#ef4444,stroke:#dc2626,color:#fff,stroke-width:2px

    class Start start
    class Document,End success
    class Escalate error
    class Log1 warning
```

## Approval Workflow

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
flowchart TD
    accTitle: Approval Workflow
    accDescr: Multi-level approval flow with manager and director review based on amount thresholds.

    Submit([Submit Request]) --> Review{Manager<br/>Review}

    Review -->|Approve| Amount{Amount ><br/>$10,000?}
    Review -->|Reject| Notify1[Notify Requester:<br/>Rejected]
    Review -->|Request Info| Return[Return for<br/>more details]

    Amount -->|Yes| Director{Director<br/>Review}
    Amount -->|No| Process[Process<br/>Request]

    Director -->|Approve| Process
    Director -->|Reject| Notify2[Notify Requester:<br/>Rejected by Director]

    Process --> Notify3[Notify Requester:<br/>Approved]

    Return --> Submit
    Notify1 --> End([End])
    Notify2 --> End
    Notify3 --> End

    classDef start fill:#6366f1,stroke:#4f46e5,color:#fff,stroke-width:2px
    classDef success fill:#22c55e,stroke:#16a34a,color:#fff,stroke-width:2px
    classDef error fill:#ef4444,stroke:#dc2626,color:#fff,stroke-width:2px

    class Submit,End start
    class Process,Notify3 success
    class Notify1,Notify2 error
```

## Customer Support Routing

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
flowchart LR
    accTitle: Customer Support Routing
    accDescr: Ticket routing by category and severity to appropriate team queues.

    Ticket([New Ticket]) --> Category{Category?}

    Category -->|Billing| Billing[Billing Team]
    Category -->|Technical| Tech{Severity?}
    Category -->|Sales| Sales[Sales Team]
    Category -->|Other| General[General Support]

    Tech -->|Critical| P1[P1 Queue<br/>Immediate response]
    Tech -->|High| P2[P2 Queue<br/>4hr response]
    Tech -->|Medium| P3[P3 Queue<br/>24hr response]
    Tech -->|Low| P4[P4 Queue<br/>Best effort]

    Billing --> Resolve([Resolve])
    Sales --> Resolve
    General --> Resolve
    P1 --> Resolve
    P2 --> Resolve
    P3 --> Resolve
    P4 --> Resolve

    classDef start fill:#6366f1,stroke:#4f46e5,color:#fff,stroke-width:2px
    classDef critical fill:#f43f5e,stroke:#e11d48,color:#fff,stroke-width:2px
    classDef error fill:#ef4444,stroke:#dc2626,color:#fff,stroke-width:2px
    classDef warning fill:#f59e0b,stroke:#d97706,color:#fff,stroke-width:2px

    class Ticket,Resolve start
    class P1 critical
    class P2 error
    class P3 warning
```

## Feature Selection Guide

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
flowchart TD
    accTitle: Diagram Type Selection Guide
    accDescr: Decision tree to help select the right Mermaid diagram type based on data type and purpose.

    Start([What do you need?]) --> Type{Data type?}

    Type -->|Process/Flow| Flow{Multiple<br/>outcomes?}
    Type -->|Timeline| Timeline{Time scale?}
    Type -->|Relationships| Rel{Data type?}
    Type -->|Statistics| Stats{Comparison?}

    Flow -->|Yes| Flowchart[Use Flowchart]
    Flow -->|No| State[Use State Diagram]

    Timeline -->|Days/Weeks| Gantt[Use Gantt Chart]
    Timeline -->|Historical| TimelineD[Use Timeline]
    Timeline -->|Tasks| Kanban[Use Kanban]

    Rel -->|Database| ER[Use ER Diagram]
    Rel -->|Code| Class[Use Class Diagram]
    Rel -->|API| Sequence[Use Sequence Diagram]

    Stats -->|Proportions| Pie[Use Pie Chart]
    Stats -->|Trends| XY[Use XY Chart]
    Stats -->|Priority| Quadrant[Use Quadrant Chart]

    classDef start fill:#6366f1,stroke:#4f46e5,color:#fff,stroke-width:2px
    classDef info fill:#8b5cf6,stroke:#7c3aed,color:#fff,stroke-width:2px

    class Start start
    class Flowchart,State,Gantt,TimelineD,Kanban,ER,Class,Sequence,Pie,XY,Quadrant info
```

## User Onboarding Flow

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
flowchart TD
    accTitle: User Onboarding Flow
    accDescr: Sign-up and onboarding flow from landing page through profile completion to dashboard.

    Landing([Visit Website]) --> CTA{Click<br/>Sign Up?}

    CTA -->|No| Browse[Browse content]
    CTA -->|Yes| Method{Sign up<br/>method?}

    Browse --> CTA

    Method -->|Email| Email[Enter email]
    Method -->|Google| Google[OAuth: Google]
    Method -->|GitHub| GitHub[OAuth: GitHub]

    Email --> Verify[Verify email]
    Google --> Profile
    GitHub --> Profile

    Verify --> Profile[Complete profile]

    Profile --> Plan{Select plan?}

    Plan -->|Free| Free[Free tier<br/>activated]
    Plan -->|Paid| Payment[Enter payment]

    Payment --> Paid[Paid plan<br/>activated]

    Free --> Onboard[Onboarding<br/>tutorial]
    Paid --> Onboard

    Onboard --> Dashboard([Dashboard])

    classDef start fill:#6366f1,stroke:#4f46e5,color:#fff,stroke-width:2px
    classDef success fill:#22c55e,stroke:#16a34a,color:#fff,stroke-width:2px
    classDef process fill:#3b82f6,stroke:#2563eb,color:#fff,stroke-width:2px

    class Landing,Dashboard start
    class Free,Paid success
    class Email,Google,GitHub,Verify,Profile,Onboard process
```

## Error Handling Logic

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
flowchart TD
    accTitle: API Error Handling Logic
    accDescr: Request validation pipeline showing checks for input, auth, permissions, and resource existence with error responses.

    Request([API Request]) --> Validate{Valid<br/>input?}

    Validate -->|No| E400[Return 400<br/>Bad Request]
    Validate -->|Yes| Auth{Authenticated?}

    Auth -->|No| E401[Return 401<br/>Unauthorized]
    Auth -->|Yes| Perm{Has<br/>permission?}

    Perm -->|No| E403[Return 403<br/>Forbidden]
    Perm -->|Yes| Find{Resource<br/>exists?}

    Find -->|No| E404[Return 404<br/>Not Found]
    Find -->|Yes| Process[Process request]

    Process --> Result{Success?}

    Result -->|Yes| S200[Return 200<br/>OK]
    Result -->|Error| E500[Return 500<br/>Server Error]

    E400 --> Log[Log error]
    E401 --> Log
    E403 --> Log
    E404 --> Log
    E500 --> Log

    classDef start fill:#6366f1,stroke:#4f46e5,color:#fff,stroke-width:2px
    classDef success fill:#22c55e,stroke:#16a34a,color:#fff,stroke-width:2px
    classDef error fill:#ef4444,stroke:#dc2626,color:#fff,stroke-width:2px
    classDef warning fill:#f59e0b,stroke:#d97706,color:#fff,stroke-width:2px
    classDef process fill:#3b82f6,stroke:#2563eb,color:#fff,stroke-width:2px

    class Request start
    class S200 success
    class E400,E401,E403,E404,E500 error
    class Process process
    class Log warning
```

## Flowchart with Subgraphs (Cross-Portal)

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
flowchart TD
    accTitle: Cross-Portal Booking Flow
    accDescr: Booking request flow across Customer, Administration, and Services Hub portals with subgraph boundaries.

    subgraph CustomerPortal["Customer Portal"]
        A([Customer Request]) --> B[Select Service]
        B --> C[Choose Times]
        C --> D[Submit Request]
    end

    subgraph AdminPortal["Administration"]
        E{CLM Reviews} --> F[Match Contractor]
        F --> G[Confirm Assignment]
    end

    subgraph ServicesHub["Services Hub"]
        H[Contractor Views] --> I[Accept Assignment]
        I --> J[Deliver Service]
        J --> K([Complete])
    end

    D --> E
    G --> H

    style CustomerPortal fill:#ede9fe,stroke:#6366f1,stroke-width:2px,color:#4f46e5
    style AdminPortal fill:#dcfce7,stroke:#22c55e,stroke-width:2px,color:#16a34a
    style ServicesHub fill:#dbeafe,stroke:#3b82f6,stroke-width:2px,color:#2563eb
```

## Usage Instructions

1. Copy the relevant template
2. Update question/decision nodes with your logic
3. Rename result/action nodes
4. Adjust flow direction (`TD`, `LR`, `TB`, `RL`)
5. Add `classDef` classes from the 8-class palette
6. Include `accTitle` and `accDescr` for accessibility
7. Test in [Mermaid Live Editor](https://mermaid.live/)

## Node Shapes

| Shape | Syntax | Use |
|-------|--------|-----|
| Rectangle | `[Text]` | Process/Action |
| Rounded | `([Text])` | Start/End |
| Diamond | `{Text}` | Decision |
| Stadium | `([Text])` | Terminal |
| Cylinder | `[(Text)]` | Database |
| Hexagon | `{{Text}}` | Preparation |
| Parallelogram | `[/Text/]` | Input/Output |
| Trapezoid | `[/Text\]` | Manual operation |
| Double circle | `(((Text)))` | Event |

## 8-Class Color Palette

```
classDef start fill:#6366f1,stroke:#4f46e5,color:#fff,stroke-width:2px
classDef process fill:#3b82f6,stroke:#2563eb,color:#fff,stroke-width:2px
classDef success fill:#22c55e,stroke:#16a34a,color:#fff,stroke-width:2px
classDef warning fill:#f59e0b,stroke:#d97706,color:#fff,stroke-width:2px
classDef error fill:#ef4444,stroke:#dc2626,color:#fff,stroke-width:2px
classDef info fill:#8b5cf6,stroke:#7c3aed,color:#fff,stroke-width:2px
classDef neutral fill:#64748b,stroke:#475569,color:#fff,stroke-width:2px
classDef critical fill:#f43f5e,stroke:#e11d48,color:#fff,stroke-width:2px
```

## Tips

- Keep decision questions short (use `<br/>` for line breaks)
- Every diamond MUST have labeled YES/NO edges (per style guide)
- Use the 8-class palette for consistent color-coding
- Add subgraphs with portal colors for cross-portal flows
- Use consistent naming for similar outcomes
- Test all paths through the diagram
