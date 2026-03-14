# Diagram Rules

## Styling (STRICT)
- Include theme init block (`%%{init: ...}%%`) on supported types: flowchart, sequenceDiagram, stateDiagram-v2, block-beta
- Use 8-class classDef palette for flowchart/stateDiagram: `start`, `process`, `success`, `warning`, `error`, `info`, `neutral`, `critical`
- Hex colors only — named colors (`red`, `blue`) are NOT supported in themeVariables
- Straight quotes only — no smart quotes (`"` not `"`)

## Accessibility (MANDATORY)
- Include `accTitle` + `accDescr` on: flowchart, sequenceDiagram, stateDiagram-v2, gantt, C4
- ER diagrams: use YAML frontmatter `title:` (no accTitle/accDescr support)
- journey/mindmap/pie/timeline: use `title` directive

## Package Colors
- Core (`nexus_store`): `fill:#ede9fe` / `rgba(99,102,241,0.1)`
- Adapters: `fill:#dbeafe` / `rgba(59,130,246,0.1)`
- Bindings: `fill:#dcfce7` / `rgba(34,197,94,0.1)`
- Generators / Shared: `fill:#f1f5f9` / `rgba(100,116,139,0.1)`

## Structure
- Error/cancellation paths required in all state diagrams
- Decision labels (YES/NO) required on all flowchart diamonds
- Related diagrams must cross-reference bidirectionally

## ER Diagram Gotchas
- Multiple constraints must be comma-separated: `PK, FK` (NOT `PK FK`)
- No commas in quoted column descriptions — use `or` instead
- No parentheses in relationship labels

## References
- Full style guide: `docs/diagrams/STYLE-GUIDE.md`
- Templates: `.claude/skills/mermaid-diagrams/assets/templates/`
- Validation: `bash .claude/skills/mermaid-diagrams/scripts/validate-mermaid.sh`

## Enforcement
- **Agent:** `.claude/agents/flow-checker.md` — validates processes and system workflows
- **Manual only:** Styling, accessibility, and package color rules require visual review or mermaid validation script
