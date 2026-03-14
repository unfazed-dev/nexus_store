# Data Visualization Template

Ready-to-use chart and visualization diagrams for metrics, priorities, timelines, and distributions.

## Quadrant Chart (Priority Matrix)

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'quadrant1Fill': '#dcfce7',
    'quadrant2Fill': '#dbeafe',
    'quadrant3Fill': '#f1f5f9',
    'quadrant4Fill': '#fef3c7',
    'quadrant1TextFill': '#16a34a',
    'quadrant2TextFill': '#2563eb',
    'quadrant3TextFill': '#475569',
    'quadrant4TextFill': '#d97706',
    'quadrantPointFill': '#6366f1',
    'quadrantPointTextFill': '#1e293b'
  }
}}%%
quadrantChart
    title Feature Priority Matrix
    x-axis Low Effort --> High Effort
    y-axis Low Impact --> High Impact

    quadrant-1 Do First
    quadrant-2 Plan Carefully
    quadrant-3 Deprioritize
    quadrant-4 Quick Wins

    Push Notifications: [0.3, 0.8]
    Booking Rescheduling: [0.5, 0.9]
    Invoice PDF Export: [0.4, 0.7]
    Dark Mode: [0.7, 0.3]
    Contractor Ratings: [0.6, 0.6]
    Wallet Auto Top-up: [0.8, 0.5]
    Service Categories: [0.2, 0.5]
    CSV Export: [0.3, 0.2]
```

## Quadrant Chart (Risk Assessment)

```mermaid
quadrantChart
    title Technical Risk Assessment
    x-axis Low Probability --> High Probability
    y-axis Low Severity --> High Severity

    quadrant-1 Monitor
    quadrant-2 Mitigate Now
    quadrant-3 Accept
    quadrant-4 Contingency Plan

    Data loss: [0.2, 0.95]
    Auth bypass: [0.15, 0.9]
    Sync conflicts: [0.7, 0.5]
    API rate limits: [0.6, 0.4]
    UI rendering bugs: [0.8, 0.2]
    Slow queries: [0.5, 0.6]
    Memory leaks: [0.4, 0.7]
    Stale cache: [0.65, 0.35]
```

## XY Chart (Bar + Line)

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'xyChart': {
      'titleColor': '#1e293b',
      'xAxisLabelColor': '#475569',
      'yAxisLabelColor': '#475569'
    }
  }
}}%%
xychart-beta
    title "Test Coverage by Module"
    x-axis ["Auth", "Booking", "Billing", "GenUI", "Profile", "Wallet", "Sync"]
    y-axis "Coverage %" 0 --> 100
    bar [92, 87, 78, 85, 90, 72, 68]
    line [80, 80, 80, 80, 80, 80, 80]
```

## XY Chart (Sprint Velocity)

```mermaid
xychart-beta
    title "Sprint Velocity (Story Points)"
    x-axis ["S7", "S8", "S9", "S10", "S11", "S12"]
    y-axis "Points" 0 --> 50
    bar [32, 28, 35, 38, 42, 40]
    line [32, 30, 31, 33, 35, 36]
```

## Timeline (Chronological Events)

```mermaid
timeline
    title Firefly Product Milestones
    section 2025
        Q1 : Project kickoff
           : Core architecture
           : Stacked MVVM setup
        Q2 : Auth + PowerSync
           : Booking CRUD
           : Customer Portal MVP
        Q3 : Services Hub
           : GenUI integration
           : Invoice generation
        Q4 : Kinly Wallet
           : Contractor onboarding
           : Admin Portal
    section 2026
        Q1 : NDIS integration
           : Compliance module
           : OTA via Shorebird
        Q2 : Public beta
           : Performance tuning
           : Multi-region
```

## Timeline (Release History)

```mermaid
timeline
    title Release History
    section v1.0
        2025-03-15 : Initial release
                   : Customer Portal
                   : Basic bookings
    section v1.1
        2025-05-01 : Services Hub launch
                   : Contractor assignments
    section v1.2
        2025-07-15 : GenUI chat
                   : MCQ Surface Paradigm
    section v1.5
        2025-11-01 : Concierge model v1.5.0
                   : Kinly Wallet
                   : 8-status booking lifecycle
```

## Pie Chart (Distribution)

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'pieStrokeColor': '#ffffff',
    'pieStrokeWidth': '2px',
    'pie1': '#6366f1',
    'pie2': '#3b82f6',
    'pie3': '#22c55e',
    'pie4': '#f59e0b',
    'pie5': '#ef4444',
    'pie6': '#8b5cf6',
    'pie7': '#64748b'
  }
}}%%
pie showData
    title Booking Status Distribution
    "Completed" : 45
    "Confirmed" : 20
    "In Progress" : 12
    "Requested" : 10
    "Paid" : 8
    "Cancelled" : 3
    "Invoiced" : 2
```

## Pie Chart (Test Distribution)

```mermaid
pie showData
    title Test Suite Composition (11,440+ tests)
    "Unit Tests" : 6200
    "Widget Tests" : 3100
    "ViewModel Tests" : 1500
    "Integration Tests" : 640
```

## Usage Instructions

1. Copy the relevant visualization template
2. Update data points, labels, and titles
3. Adjust axis ranges and quadrant labels as needed
4. Test in [Mermaid Live Editor](https://mermaid.live/)

## Chart Type Selection

| Chart Type | Best For | Axes |
|------------|----------|------|
| `quadrantChart` | Priority/risk matrices, 2D comparisons | 2 labeled axes, 4 named quadrants |
| `xychart-beta` | Trends, comparisons, velocity | Named x categories, numeric y |
| `timeline` | Chronological events, release history | Time sections + events |
| `pie` | Distribution, composition | Category + value |

## Syntax Reference

### Quadrant Chart
| Feature | Syntax |
|---------|--------|
| Point | `Label: [x, y]` where x,y are 0-1 |
| Quadrant names | `quadrant-1` through `quadrant-4` |
| Axes | `x-axis Low --> High` |

### XY Chart
| Feature | Syntax |
|---------|--------|
| Categories | `x-axis ["A", "B", "C"]` |
| Range | `y-axis "Label" 0 --> 100` |
| Bar series | `bar [10, 20, 30]` |
| Line series | `line [15, 15, 15]` |

### Timeline
| Feature | Syntax |
|---------|--------|
| Section | `section Name` |
| Event | `Date : Event description` |
| Multi-line | `Date : Event 1` newline `: Event 2` |

### Pie
| Feature | Syntax |
|---------|--------|
| Slice | `"Label" : value` |
| Show values | `pie showData` |

## Tips

- Quadrant charts: coordinates are 0.0 to 1.0 on both axes
- XY charts: bar and line series must have same number of values as x-axis categories
- Timeline: use sections for grouping, indent events under dates
- Pie: values are proportional, not percentages — Mermaid calculates %
- Pie and timeline do NOT support theme init blocks in some renderers
- Use `showData` on pie charts to display numeric values
