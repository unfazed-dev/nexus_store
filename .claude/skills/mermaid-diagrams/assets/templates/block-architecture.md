# Block Architecture Template

Ready-to-use block diagrams for grid-based system layouts and infrastructure visualization.

## Firefly System Architecture

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
block-beta
    columns 3

    block:clients["Client Applications"]:3
        columns 3
        customer["Customer Portal\n(Flutter)"]
        services["Services Hub\n(Flutter)"]
        admin["Administration\n(Flutter)"]
    end

    space:3

    block:sync["Sync Layer"]:3
        columns 2
        powersync["PowerSync\nOffline-First Sync"]
        nexus["NexusStore\nReactive Data Layer"]
    end

    space:3

    block:backend["Backend Services"]:3
        columns 3
        auth["Supabase Auth\nJWT + OAuth"]
        db["Supabase Database\nPostgreSQL + RLS"]
        storage["Supabase Storage\nFiles + Media"]
    end

    space:3

    block:infra["Infrastructure"]:3
        columns 4
        fcm["Firebase\nCloud Messaging"]
        shorebird["Shorebird\nOTA Updates"]
        sentry["Sentry\nError Tracking"]
        edge["Edge Functions\nServerless"]
    end

    customer --> powersync
    services --> powersync
    admin --> powersync
    powersync --> nexus
    nexus --> auth
    nexus --> db
    nexus --> storage
    edge --> db

    style clients fill:#ede9fe,stroke:#6366f1,color:#4f46e5
    style sync fill:#dbeafe,stroke:#3b82f6,color:#2563eb
    style backend fill:#dcfce7,stroke:#22c55e,color:#16a34a
    style infra fill:#f1f5f9,stroke:#64748b,color:#475569
```

## Microservices Layout

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
block-beta
    columns 4

    block:gateway["API Gateway"]:4
        columns 1
        gw["Load Balancer / API Gateway"]
    end

    space:4

    block:services["Services"]:4
        columns 4
        authSvc["Auth\nService"]
        bookingSvc["Booking\nService"]
        billingSvc["Billing\nService"]
        notifySvc["Notification\nService"]
    end

    space:4

    block:data["Data Stores"]:4
        columns 4
        authDb[("Auth DB")]
        bookingDb[("Booking DB")]
        billingDb[("Billing DB")]
        queue[["Message\nQueue"]]
    end

    gw --> authSvc
    gw --> bookingSvc
    gw --> billingSvc
    authSvc --> authDb
    bookingSvc --> bookingDb
    billingSvc --> billingDb
    bookingSvc --> queue
    queue --> notifySvc

    style gateway fill:#6366f1,stroke:#4f46e5,color:#fff
    style services fill:#3b82f6,stroke:#2563eb,color:#fff
    style data fill:#64748b,stroke:#475569,color:#fff
```

## Stacked MVVM Layer Diagram

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
block-beta
    columns 1

    block:ui["UI Layer (Views)"]:1
        columns 3
        view1["BookingListView"]
        view2["BookingDetailView"]
        view3["BookingCreateView"]
    end

    space

    block:vm["ViewModel Layer"]:1
        columns 3
        vm1["BookingListViewModel"]
        vm2["BookingDetailViewModel"]
        vm3["BookingCreateViewModel"]
    end

    space

    block:svc["Service Layer"]:1
        columns 2
        svc1["BookingService"]
        svc2["WalletService"]
    end

    space

    block:repo["Repository Layer"]:1
        columns 2
        repo1["BookingsRepository"]
        repo2["WalletRepository"]
    end

    space

    block:store["Data Layer"]:1
        columns 2
        nx["NexusStore"]
        ps["PowerSync"]
    end

    view1 --> vm1
    view2 --> vm2
    view3 --> vm3
    vm1 --> svc1
    vm2 --> svc1
    vm3 --> svc1
    vm3 --> svc2
    svc1 --> repo1
    svc2 --> repo2
    repo1 --> nx
    repo2 --> nx
    nx --> ps

    style ui fill:#ede9fe,stroke:#6366f1,color:#4f46e5
    style vm fill:#dbeafe,stroke:#3b82f6,color:#2563eb
    style svc fill:#dcfce7,stroke:#22c55e,color:#16a34a
    style repo fill:#fef3c7,stroke:#f59e0b,color:#d97706
    style store fill:#f1f5f9,stroke:#64748b,color:#475569
```

## Deployment Pipeline

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
block-beta
    columns 5

    dev["Developer\nPush"]
    ci["CI/CD\nPipeline"]
    test["Test\nSuite"]
    stage["Staging\nDeploy"]
    prod["Production\nDeploy"]

    dev --> ci
    ci --> test
    test --> stage
    stage --> prod

    block:checks["Quality Gates"]:5
        columns 5
        lint["Flutter\nAnalyze"]
        unit["Unit\nTests"]
        integ["Integration\nTests"]
        review["Code\nReview"]
        approve["Release\nApproval"]
    end

    style dev fill:#64748b,stroke:#475569,color:#fff
    style ci fill:#3b82f6,stroke:#2563eb,color:#fff
    style test fill:#f59e0b,stroke:#d97706,color:#fff
    style stage fill:#8b5cf6,stroke:#7c3aed,color:#fff
    style prod fill:#22c55e,stroke:#16a34a,color:#fff
    style checks fill:#f1f5f9,stroke:#64748b,color:#475569
```

## Usage Instructions

1. Copy the relevant block architecture template
2. Adjust `columns N` for your layout needs
3. Update block labels and nesting
4. Add connections with `-->` arrows
5. Apply portal-colored styles to blocks
6. Test in [Mermaid Live Editor](https://mermaid.live/)

## Block Diagram Syntax Reference

| Feature | Syntax | Example |
|---------|--------|---------|
| Columns | `columns N` | `columns 3` |
| Block | `id["Label"]` | `auth["Auth Service"]` |
| Block group | `block:id["Label"]:span` | `block:svc["Services"]:3` |
| Database | `id[("Label")]` | `db[("PostgreSQL")]` |
| Queue | `id[["Label"]]` | `q[["Message Queue"]]` |
| Space | `space` or `space:N` | `space:3` |
| Arrow | `a --> b` | `app --> api` |
| Style | `style id fill:...,stroke:...` | See examples above |

## Tips

- Use `columns N` at the top to set the grid width
- Blocks can span multiple columns with `:N` suffix
- Use `space` or `space:N` for visual spacing between rows
- Nest blocks with `block:id["Label"]:span ... end`
- Style blocks using Firefly portal colors for consistency
- Block diagrams are ideal for layered architectures and infrastructure overviews
- For flow/sequence, use flowchart or sequenceDiagram instead
