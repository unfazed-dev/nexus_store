---
name: skills-factory
description: Advanced skill generation factory for creating Claude skills on any topic. Use when user wants to create a new skill, generate multiple skills, design skill architectures, or systematically build specialized Claude capabilities. Supports rapid prototyping, domain analysis, quality validation, and multi-skill orchestration.
---

# Skills Factory

A comprehensive system for generating high-quality Claude skills on any topic, domain, or workflow.

## Overview

The Skills Factory transforms user requirements into production-ready Claude skills through systematic analysis, intelligent templating, and quality validation. It generates skills that follow Anthropic's best practices for progressive disclosure, appropriate freedom levels, and efficient context usage.

## Workflow

```
User Request → [MCQ Discovery?] → Domain Analysis → Skill Architecture → Content Generation → Validation → Package
                     │
                     ├── Detailed request? → Skip MCQ, proceed to Domain Analysis
                     └── Vague request? → AskUserQuestion (Round 1 + Round 2) → Map answers to parameters
```

## Interactive Skill Discovery (AskUserQuestion)

When a user requests skill generation without providing sufficient detail, use Claude Code's `AskUserQuestion` tool to gather requirements through focused multiple-choice questions.

### When to Use MCQ

**USE AskUserQuestion when:**
- User provides only a vague description (e.g., "create a skill for X")
- Skill type cannot be confidently determined from keywords
- User explicitly asks for help deciding skill parameters
- Multiple valid interpretations exist for the request

**SKIP AskUserQuestion when:**
- User provides detailed specification with explicit type, complexity, and features
- User passes command-line arguments specifying all parameters
- User says "quick" or "just generate" indicating they want defaults
- Request clearly matches a single skill type with high confidence

### Question Flow

**Round 1: Core Classification (2 Questions)**

Ask these questions to establish the foundation:

```json
{
  "questions": [
    {
      "header": "Category",
      "question": "What type of skill are you creating?",
      "options": [
        {"label": "Technical/Code", "description": "Scripts, code generation, debugging, testing tools"},
        {"label": "Workflow/Process", "description": "Step-by-step procedures, decision trees, automation"},
        {"label": "Reference/Knowledge", "description": "Documentation, standards, compliance, terminology"},
        {"label": "Integration/API", "description": "External service connections, webhooks, authentication"}
      ],
      "multiSelect": false
    },
    {
      "header": "Complexity",
      "question": "What complexity level should this skill have?",
      "options": [
        {"label": "Simple", "description": "Single SKILL.md file, under 200 lines, no dependencies"},
        {"label": "Standard", "description": "SKILL.md with references folder, 200-500 lines total"},
        {"label": "Complex", "description": "Full structure with scripts, references, and assets"}
      ],
      "multiSelect": false
    }
  ]
}
```

**Round 2: Features & Technology (2 Questions)**

After receiving Round 1 answers, ask about specific features:

```json
{
  "questions": [
    {
      "header": "Features",
      "question": "What should this skill include? (Select all that apply)",
      "options": [
        {"label": "Python Scripts", "description": "Executable scripts for deterministic operations"},
        {"label": "Reference Docs", "description": "Detailed documentation for complex topics"},
        {"label": "Templates/Assets", "description": "Reusable templates, samples, or configuration files"},
        {"label": "None Required", "description": "Core SKILL.md only, no additional resources"}
      ],
      "multiSelect": true
    },
    {
      "header": "Domain",
      "question": "What domain or technology is this skill for?",
      "options": [
        {"label": "Flutter/Dart", "description": "Mobile/web development with Flutter framework"},
        {"label": "Python/Backend", "description": "Python scripts, APIs, data processing"},
        {"label": "DevOps/Tooling", "description": "CI/CD, automation, infrastructure tools"},
        {"label": "Domain-Agnostic", "description": "Not technology-specific, general purpose"}
      ],
      "multiSelect": false
    }
  ]
}
```

### Answer Mapping

Map user selections to generation parameters:

| Category Selection | Skill Type | Template |
|-------------------|------------|----------|
| Technical/Code | `technical` | Code examples, scripts, troubleshooting |
| Workflow/Process | `workflow` | Decision trees, steps, validation |
| Reference/Knowledge | `reference` | Concepts, terminology, guidelines |
| Integration/API | `integration` | Auth, endpoints, error handling |

| Complexity Selection | Structure | Lines Target |
|---------------------|-----------|--------------|
| Simple | SKILL.md only | < 200 lines |
| Standard | SKILL.md + references/ | 200-500 lines |
| Complex | scripts/ + references/ + assets/ | 500+ lines |

| Features Selection | Generated Folders |
|-------------------|-------------------|
| Python Scripts | `scripts/` with example.py |
| Reference Docs | `references/` with reference.md |
| Templates/Assets | `assets/` with sample templates |
| None Required | SKILL.md only |

| Domain Selection | Language for Examples |
|-----------------|----------------------|
| Flutter/Dart | `dart` |
| Python/Backend | `python` |
| DevOps/Tooling | `bash` or `yaml` |
| Domain-Agnostic | `python` (default) |

### Adaptive Behavior

1. **Single-round shortcut:** If Round 1 answers indicate simple/focused skill, skip Round 2
2. **Custom input handling:** When user selects "Other", incorporate their text into domain analysis
3. **Confirmation before generation:** After MCQ, summarize the planned skill structure before generating

### Example Interaction

**User:** "Create a skill for managing database migrations"

**Claude (recognizing ambiguity):** Uses AskUserQuestion Round 1

**User selections:**
- Category: Workflow/Process
- Complexity: Standard

**Claude:** Uses AskUserQuestion Round 2

**User selections:**
- Features: Python Scripts, Reference Docs
- Domain: Python/Backend

**Claude generates:**
```
database-migrations/
├── SKILL.md              (workflow template)
├── scripts/
│   └── run_migration.py
└── references/
    └── migration-patterns.md
```

---

**Decision Flow:**

1. **Is this a single skill or skill suite?**
   - Single topic → Generate one skill
   - Complex domain → Design interconnected skill suite

2. **What's the skill category?**
   - Technical/Code → Include scripts, code examples, deterministic operations
   - Knowledge/Reference → Focus on references, schemas, documentation
   - Creative/Design → Include templates, assets, style guides
   - Workflow/Process → Include decision trees, sequential steps
   - Integration/API → Include authentication, endpoint references, scripts

3. **What freedom level is appropriate?**
   - High: Guidelines, heuristics, creative latitude
   - Medium: Pseudocode, parameterized scripts
   - Low: Exact scripts, strict sequences, critical operations

## Skill Generation Process

### Step 1: Domain Analysis

Extract from user request:

```
DOMAIN_ANALYSIS:
├── Core Purpose: [What problem does this skill solve?]
├── Target Users: [Who uses this skill?]
├── Key Operations: [List 3-7 primary tasks]
├── Inputs: [What does the skill receive?]
├── Outputs: [What does the skill produce?]
├── Failure Modes: [What can go wrong?]
├── Dependencies: [External tools, APIs, libraries]
└── Complexity Level: [Simple | Medium | Complex]
```

### Step 2: Architecture Design

Determine skill structure:

**Simple Skills (1 file):**
- Single-purpose operations
- < 200 lines of guidance
- No external dependencies

**Standard Skills (SKILL.md + references):**
- Multi-operation capabilities
- Domain-specific knowledge
- 200-500 lines total

**Complex Skills (full structure):**
- Multi-step workflows
- Scripts for deterministic operations
- Reference documentation
- Asset templates

```
skill-name/
├── SKILL.md              # Core instructions (required)
├── scripts/              # Executable code (optional)
│   ├── main_operation.py
│   └── helpers/
├── references/           # Documentation (optional)
│   ├── api_reference.md
│   └── examples.md
└── assets/               # Templates/resources (optional)
    ├── templates/
    └── samples/
```

### Step 3: Frontmatter Generation

Create optimal triggering metadata:

```yaml
---
name: [hyphen-case, max 40 chars, matches directory]
description: [Comprehensive description covering:
  1. WHAT the skill does (capabilities)
  2. WHEN to use it (trigger scenarios)
  3. Key file types or contexts
  Max 200 chars, third-person voice]
---
```

**Description Formula:**
`[Core capability] for [domain/file type]. Use when [trigger 1], [trigger 2], or [trigger 3].`

**Examples:**
- `Comprehensive Dart/Flutter development toolkit with code generation, testing patterns, and package management. Use when building Flutter apps, writing Dart code, or debugging mobile/web applications.`
- `NDIS service coordination workflow manager with participant tracking, provider matching, and compliance automation. Use when managing NDIS plans, coordinating services, or generating compliance reports.`

### Step 4: Body Content Generation

Structure based on skill type:

**WORKFLOW-BASED** (sequential processes):
```markdown
# Skill Name

## Overview
[1-2 sentences]

## Workflow Decision Tree
[Entry point logic]

## Step 1: [Action]
[Instructions]

## Step 2: [Action]
[Instructions]

## Common Patterns
[Reusable approaches]
```

**TASK-BASED** (tool collections):
```markdown
# Skill Name

## Overview
[1-2 sentences]

## Quick Start
[Minimal working example]

## Task: [Operation 1]
[Instructions + code]

## Task: [Operation 2]
[Instructions + code]

## Reference
[Links to detailed docs]
```

**REFERENCE/GUIDELINES** (standards):
```markdown
# Skill Name

## Overview
[1-2 sentences]

## Core Principles
[Foundational rules]

## Guidelines
[Specific requirements]

## Examples
[Good vs bad patterns]
```

**CAPABILITIES-BASED** (integrated systems):
```markdown
# Skill Name

## Overview
[1-2 sentences]

## Core Capabilities

### 1. [Capability Name]
[Description + usage]

### 2. [Capability Name]
[Description + usage]

## Integration Patterns
[How capabilities work together]
```

### Step 5: Content Quality Checklist

Before finalizing:

- [ ] **Conciseness**: Every paragraph justifies its token cost
- [ ] **Actionability**: Claude can execute without clarification
- [ ] **Examples**: Concrete over abstract where possible
- [ ] **Progressive Disclosure**: Details in references, not core SKILL.md
- [ ] **No Redundancy**: Information lives in ONE place
- [ ] **Imperative Voice**: "Extract the data" not "You should extract"
- [ ] **Third Person Description**: "Processes files" not "I process files"

### Step 6: Validation

Run validation checks:

```python
# Quick validation criteria
VALIDATION = {
    'frontmatter': {
        'name': 'required, hyphen-case, ≤40 chars',
        'description': 'required, ≤1024 chars, third-person',
    },
    'structure': {
        'SKILL.md': 'required, < 500 lines ideal',
        'scripts/': 'optional, executable, tested',
        'references/': 'optional, referenced from SKILL.md',
        'assets/': 'optional, not loaded to context',
    },
    'content': {
        'no_readme': True,
        'no_changelog': True,
        'no_installation_guide': True,
    }
}
```

## Skill Templates by Domain

### Technical/Code Skill Template

```markdown
---
name: [technology]-toolkit
description: [Technology] development toolkit with [key features]. Use when [trigger scenarios].
---

# [Technology] Toolkit

## Quick Start

\`\`\`[language]
[Minimal working example]
\`\`\`

## Core Operations

### [Operation 1]
\`\`\`[language]
[Code example]
\`\`\`

### [Operation 2]
\`\`\`[language]
[Code example]
\`\`\`

## Common Patterns

[Reusable code patterns]

## Troubleshooting

| Problem | Solution |
|---------|----------|
| [Issue] | [Fix] |

## Resources

- **Advanced Usage**: See references/advanced.md
- **API Reference**: See references/api.md
```

### Workflow/Process Skill Template

```markdown
---
name: [process]-workflow
description: [Process] workflow management with [capabilities]. Use when [trigger scenarios].
---

# [Process] Workflow

## Overview

[Brief description of the workflow]

## Workflow Decision Tree

1. **Determine the task type:**
   - [Condition A] → Follow "Path A" below
   - [Condition B] → Follow "Path B" below

## Path A: [Workflow Name]

### Step 1: [Action]
[Instructions]

### Step 2: [Action]
[Instructions]

## Path B: [Workflow Name]

### Step 1: [Action]
[Instructions]

## Validation Checklist

- [ ] [Checkpoint 1]
- [ ] [Checkpoint 2]
```

### Integration/API Skill Template

```markdown
---
name: [service]-integration
description: [Service] API integration with [capabilities]. Use when [trigger scenarios].
---

# [Service] Integration

## Authentication

\`\`\`python
[Auth setup code]
\`\`\`

## Core Endpoints

### [Endpoint 1]
\`\`\`python
[Usage example]
\`\`\`

### [Endpoint 2]
\`\`\`python
[Usage example]
\`\`\`

## Error Handling

| Error Code | Meaning | Resolution |
|------------|---------|------------|
| [Code] | [Description] | [Fix] |

## Rate Limits

[Rate limit information and handling]
```

### Domain Knowledge Skill Template

```markdown
---
name: [domain]-expertise
description: [Domain] knowledge base with [coverage areas]. Use when [trigger scenarios].
---

# [Domain] Expertise

## Core Concepts

### [Concept 1]
[Explanation]

### [Concept 2]
[Explanation]

## Terminology

| Term | Definition |
|------|------------|
| [Term] | [Definition] |

## Best Practices

1. [Practice 1]
2. [Practice 2]

## Common Mistakes

- **[Mistake]**: [Why it's wrong and how to fix]

## Resources

- For detailed schemas: See references/schemas.md
- For examples: See references/examples.md
```

## Script Templates

### Python Helper Script

```python
#!/usr/bin/env python3
"""
[Script description]

Usage:
    python script_name.py <input> [options]

Examples:
    python script_name.py input.txt
    python script_name.py input.txt --output result.txt
"""

import sys
import argparse
from pathlib import Path


def main(input_path: str, output_path: str = None) -> None:
    """Main processing function."""
    # Implementation
    pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="[Description]")
    parser.add_argument("input", help="Input file path")
    parser.add_argument("--output", "-o", help="Output file path")
    args = parser.parse_args()
    
    main(args.input, args.output)
```

### Validation Script

```python
#!/usr/bin/env python3
"""Validate [skill-name] outputs."""

import json
import sys


def validate(data: dict) -> list[str]:
    """Return list of validation errors, empty if valid."""
    errors = []
    
    # Required fields
    required = ['field1', 'field2']
    for field in required:
        if field not in data:
            errors.append(f"Missing required field: {field}")
    
    # Type checks
    if 'count' in data and not isinstance(data['count'], int):
        errors.append("'count' must be an integer")
    
    return errors


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: validate.py <input.json>")
        sys.exit(1)
    
    with open(sys.argv[1]) as f:
        data = json.load(f)
    
    errors = validate(data)
    if errors:
        print("Validation failed:")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)
    else:
        print("Validation passed!")
```

## Multi-Skill Suite Design

For complex domains requiring multiple interconnected skills:

```
domain-suite/
├── core/
│   └── domain-core/           # Shared concepts and utilities
│       ├── SKILL.md
│       └── references/
├── workflows/
│   ├── domain-workflow-a/     # Specific workflow
│   └── domain-workflow-b/
├── integrations/
│   ├── domain-api-x/          # External service integration
│   └── domain-api-y/
└── templates/
    └── domain-templates/       # Shared templates and assets
```

**Suite Design Principles:**
1. Each skill is independently useful
2. Skills reference each other via clear signals
3. Shared knowledge lives in core skill
4. Workflows build on core capabilities

## Quality Metrics

Measure skill effectiveness:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Trigger Accuracy | >90% | Skill activates for relevant tasks |
| Completion Rate | >85% | Tasks completed successfully |
| Token Efficiency | Minimal | Compare to baseline without skill |
| Error Rate | <10% | Failed operations / total |

## Anti-Patterns to Avoid

1. **Kitchen Sink**: Don't include everything; be focused
2. **Redundant Docs**: No README, CHANGELOG, INSTALLATION
3. **Vague Descriptions**: Must specify WHEN to use
4. **Context Bloat**: Move details to references
5. **Untested Scripts**: All scripts must be verified
6. **First Person**: Use "Processes..." not "I process..."
7. **Explanation Overload**: Claude is smart; be concise
## Output Location

**All generated skills are created in `.claude/skills/` directory** within the current project:

```
project-root/
├── .claude/
│   └── skills/
│       ├── my-skill/
│       │   ├── SKILL.md
│       │   ├── scripts/
│       │   └── references/
│       └── another-skill/
├── lib/
├── pubspec.yaml
└── ...
```

This location ensures Claude automatically discovers and uses the skills in the project context.

## Generating Skills

To generate a new skill:

```bash
# Generate in current project (outputs to .claude/skills/)
scripts/generate_skill.py "Flutter widget testing toolkit"
# Creates: .claude/skills/flutter-widget-testing/

# Generate with specific type
scripts/generate_skill.py "NDIS compliance checker" --type workflow
# Creates: .claude/skills/ndis-compliance-checker/

# Generate with custom name
scripts/generate_skill.py "REST API helper" --name api-toolkit
# Creates: .claude/skills/api-toolkit/

# Custom output path (override default)
scripts/generate_skill.py "My skill" --path /custom/path
```

**Post-generation steps:**
1. Review generated structure in `.claude/skills/<skill-name>/`
2. Customize SKILL.md content for specific needs
3. Validate: `scripts/validate_skill.py .claude/skills/<skill-name>`

For skill suite generation, use `scripts/generate_suite.py` with domain specification.
