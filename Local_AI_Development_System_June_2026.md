# Local AI Development System (June 2026)

## Philosophy

Build a development system rather than a collection of AI tools. The goal is a long-lived repository that becomes easier for both humans and local AI agents to understand over time.

Core principles:

- Keep the stack intentionally simple.
- Store project knowledge in the repository, not only in conversations.
- Prefer small, testable changes.
- Treat documentation as executable context.
- Continuously extract knowledge from development into durable documentation.

## Recommended Stack

### Model Server
- llama.cpp

### Primary Coding CLI
- Pi

### Companion Tools
- Aider (optional second opinion)
- Playwright
- Native test framework (for example node:test or pytest)
- Git
- Docker
- MCP servers as needed (filesystem, Git, SQLite, browser, etc.)

## Repository Layout

```
repo/
├── AGENTS.md
├── README.md
├── ARCHITECTURE.md
├── memory/
├── patterns/
├── prompts/
├── specs/
├── tests/
├── scripts/
├── src/
├── public/
├── package.json
└── playwright.config.js
```

## Context Stack

Agents should load context in this order:

1. AGENTS.md
2. Relevant memory documents
3. Relevant implementation patterns
4. Relevant specifications
5. Relevant source files
6. Relevant tests

Avoid loading the entire repository when only a small portion is relevant.

## Knowledge Directories

### AGENTS.md
A concise entry point (roughly 100–200 lines):
- project overview
- coding rules
- architecture summary
- where to find deeper documentation
- commands

### memory/
Long-lived project knowledge:
- architecture
- domain model
- API
- database
- design decisions
- terminology
- deployment
- testing
- known gotchas

### patterns/
Implementation recipes:
- new API endpoint
- database migration
- frontend feature
- Playwright test
- bug fix workflow
- release checklist

### prompts/
Reusable workflows:
- add feature
- fix bug
- review code
- refactor
- implement spec
- security review
- release

## Preferred Workflow

1. Understand the request.
2. Read AGENTS.md.
3. Load only the relevant memory documents.
4. Load only the relevant implementation patterns.
5. Read the affected code.
6. Read existing tests.
7. Produce a short implementation plan.
8. Implement small changes.
9. Run tests.
10. Run Playwright when UI behavior changes.
11. Update documentation if required.
12. Commit.

## Testing Strategy

- Fast unit/integration tests run frequently.
- Playwright validates browser behavior.
- Prefer fixing the root cause over changing tests.

## Repository Maintenance

Run periodically:

- Extract new knowledge into memory/.
- Add or refine implementation patterns.
- Improve reusable prompts.
- Remove obsolete documentation.
- Review architecture drift.
- Review TODOs.
- Keep AGENTS.md concise.

## Hardware Guidance

- 8 GB VRAM: 7B–8B coding models.
- 16 GB VRAM: 14B class models.
- 24 GB VRAM: 20B–32B quantized models.
- 2×24 GB or larger: larger coding models and more experimentation.

The coding harness and workflow generally matter more than the model alone.

## Guiding Principles

- Simplicity beats novelty.
- Explicit architecture beats hidden framework behavior.
- Documentation is part of the system.
- Preserve decisions, not conversations.
- Build reusable workflows instead of one-off prompts.
- Let project knowledge accumulate in the repository.

## Vision

The repository itself becomes part of the AI system. As memory/, patterns/, prompts/, tests and documentation mature, changing or upgrading models becomes easier because the important knowledge lives alongside the code rather than inside a single AI session.
