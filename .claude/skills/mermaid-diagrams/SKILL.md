---
name: mermaid-diagrams
description: "Mermaid diagram generation — sequence, flowchart, ER, Gantt, C4, state, journey, mindmap, block, charts with templates and scripts"
metadata:
  scope: core
  status: active
  review_by: "2026-06-09"
  harness_compatible: true
  referenced_by:
    - flow-checker
  related_rules:
    - .claude/rules/diagrams.md
---

# Mermaid Diagrams
> Comprehensive Mermaid diagram generation (v11.12.x) with 11 template files, 50+ example diagrams, validation/rendering scripts, and project-specific styling.

## Harness Integration
- **Extends:** `.claude/rules/diagrams.md` (styling, accessibility, portal colors, ER gotchas)
- **Agent:** `flow-checker` validates FLOWS.md diagrams against code implementation
- **Invariant:** `flow-route-sync.dart` ensures flow docs match route configuration
- Used in `FLOWS.md` files throughout the codebase for feature flow documentation
- Templates provide consistent diagram styling via `docs/diagrams/STYLE-GUIDE.md`
- Diagrams include accessibility metadata where supported

## When to Use
- Creating `FLOWS.md` diagrams for features
- Documenting API flows (sequence diagrams)
- Modeling entity lifecycles (state diagrams)
- Modeling database schemas (ER diagrams)
- Visualizing decision logic (flowcharts with 8-class palette)
- Planning project timelines (Gantt charts)
- Documenting system architecture (C4 and block diagrams)
- Mapping user journeys and experiences
- Creating feature/structure mindmaps
- Cross-portal flows with portal-colored boundaries
- Data visualization (quadrant, XY chart, timeline, pie)

## Diagram Type Selection

| Need | Diagram Type | Template |
|------|-------------|----------|
| Entity states/lifecycle | `stateDiagram-v2` | `state-lifecycle.md` |
| API interactions | `sequenceDiagram` | `api-flow.md` |
| Cross-portal E2E flows | `sequenceDiagram` + boxes | `cross-portal-flow.md` |
| Decision/routing logic | `flowchart TD` | `decision-tree.md` |
| Database relationships | `erDiagram` | `database-schema.md` |
| Project timelines | `gantt` | `project-timeline.md` |
| System architecture | `C4Context`/`C4Container` | `software-architecture.md` |
| Grid-based layouts | `block-beta` | `block-architecture.md` |
| User experience | `journey` | `user-journey.md` |
| Feature/structure maps | `mindmap` | `mindmap-feature.md` |
| Priority matrices | `quadrantChart` | `data-visualization.md` |
| Bar/line charts | `xychart-beta` | `data-visualization.md` |
| Chronological events | `timeline` | `data-visualization.md` |
| Distributions | `pie` | `data-visualization.md` |
| Network packet formats | `packet-beta` | (no template yet) |
| System architecture | `architecture-beta` | (no template yet) |
| Kanban boards | `kanban` | (no template yet) |
| Radar/spider charts | `radar` | (no template yet) |

## Available Templates

### 1. API Flow (`assets/templates/api-flow.md`)
`sequenceDiagram` for REST APIs, CRUD operations, error handling, async processing, OAuth2.

### 2. Decision Tree (`assets/templates/decision-tree.md`)
`flowchart TD/LR` with 8-class color palette, subgraph styling, cross-portal boundaries.

### 3. Database Schema (`assets/templates/database-schema.md`)
`erDiagram` for blog, e-commerce, SaaS multi-tenant, and domain booking schemas.

### 4. Project Timeline (`assets/templates/project-timeline.md`)
`gantt` for release plans, sprints, roadmaps, and marketing campaigns.

### 5. Software Architecture (`assets/templates/software-architecture.md`)
`C4Context`, `C4Container`, `C4Component` with system context examples.

### 6. State Lifecycle (`assets/templates/state-lifecycle.md`)
`stateDiagram-v2` with booking 8-status lifecycle, nested states, choice nodes, fork/join, concurrent regions.

### 7. User Journey (`assets/templates/user-journey.md`)
`journey` for customer service request, contractor onboarding, CLM workflow, multi-portal access.

### 8. Mindmap (`assets/templates/mindmap-feature.md`)
`mindmap` for portal structure, GenUI entity coverage, feature dependencies, tech stack.

### 9. Cross-Portal Flow (`assets/templates/cross-portal-flow.md`)
`sequenceDiagram` with portal-colored `box` groups, `alt/par/critical` blocks, PowerSync sync, auth branching.

### 10. Block Architecture (`assets/templates/block-architecture.md`)
`block-beta` for system layouts, microservices, Stacked MVVM layers, deployment pipelines.

### 11. Data Visualization (`assets/templates/data-visualization.md`)
`quadrantChart`, `xychart-beta`, `timeline`, `pie` for priority matrices, test coverage, milestones, distributions.

## Styling Standards

### Theme Init Block (for supported types only)
```
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
```

### Theme Compatibility

| Diagram Type | Theme Init | accTitle/accDescr | Title Method |
|---|---|---|---|
| `flowchart` | Yes | Yes | In accTitle |
| `sequenceDiagram` | Yes | Yes | In accTitle |
| `stateDiagram-v2` | Yes | Yes | In accTitle |
| `block-beta` | Yes | No | N/A |
| `erDiagram` | No | No | YAML frontmatter `title:` |
| `gantt` | No | Yes (accTitle + accDescr) | `title` directive |
| `C4Context/Container` | No | Yes | `title` directive |
| `journey` | No | No | `title` directive |
| `mindmap` | No | No | Root node |
| `pie` | No | No | `title` keyword |
| `quadrantChart` | Custom vars | No | `title` directive |
| `xychart-beta` | Custom vars | No | `title` directive |
| `timeline` | No | No | `title` directive |

### 8-Class Color Palette (for flowchart/stateDiagram)
`start` (Indigo #6366f1), `process` (Blue #3b82f6), `success` (Green #22c55e), `warning` (Amber #f59e0b), `error` (Red #ef4444), `info` (Purple #8b5cf6), `neutral` (Slate #64748b), `critical` (Rose #f43f5e)

### Portal Colors
- Customer: `rgba(99,102,241,0.1)` / `fill:#ede9fe`
- Services Hub: `rgba(59,130,246,0.1)` / `fill:#dbeafe`
- Administration: `rgba(34,197,94,0.1)` / `fill:#dcfce7`
- Shared: `rgba(100,116,139,0.1)` / `fill:#f1f5f9`

## Advanced Syntax Quick Reference

### Sequence Diagrams
- `alt/else/end` — conditional paths
- `par/and/end` — parallel execution
- `critical/option/end` — try/catch with fallbacks
- `break/end` — early exit
- `box color Name ... end` — participant grouping

### State Diagrams
- `state name <<choice>>` — conditional routing
- `state name <<fork>>` / `<<join>>` — parallel transitions
- `state Parent { ... }` — nested states
- `--` inside state — concurrent regions

### Flowcharts
- `classDef name fill:...,stroke:...` — reusable classes
- `class A,B className` — apply class to nodes
- `subgraph Name ... end` — grouped sections
- `style SubName fill:...,stroke:...` — subgraph styling
- Edge IDs (v11.12+) — `A -- id1 --> B` for per-edge styling, classes, animation
- 30 new shapes with general shape syntax (v11.x)

## Scripts

### Validate Diagrams
```bash
bash .claude/skills/mermaid-diagrams/scripts/validate-mermaid.sh docs/diagrams/
bash .claude/skills/mermaid-diagrams/scripts/validate-mermaid.sh path/to/file.md
```
Requires: `npm install -g @mermaid-js/mermaid-cli`

### Render to SVG/PNG
```bash
bash .claude/skills/mermaid-diagrams/scripts/render-diagrams.sh docs/diagrams/
bash .claude/skills/mermaid-diagrams/scripts/render-diagrams.sh --format png path/to/file.md
```
Output: `docs/diagrams/.rendered/` (gitignored)

## Version Notes (v11.12.x)
- Parser upgraded to Langium v4 (`@mermaid-js/parser` 1.0.0)
- ELK renderer available as alternative layout engine for complex diagrams
- C4 diagrams have **limited-support** status — prefer `block-beta` for system architecture
- v10.x is in maintenance mode — use v11.x features

## References
- Templates: `.claude/skills/mermaid-diagrams/assets/templates/`
- Scripts: `.claude/skills/mermaid-diagrams/scripts/`
- Style guide: `docs/diagrams/STYLE-GUIDE.md`
- Feature flow docs: `lib/**/FLOWS.md`
- Mermaid docs: https://mermaid.js.org/
- Live editor: https://mermaid.live/
