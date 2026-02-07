# AGENTS.md — Start Here

> This file is auto-discovered by AI agents. It bootstraps the entire project workflow.

## Instructions for AI Agent

**Before doing anything else, read and absorb the full template structure in this order:**

1. Read `02-agent/AGENTS.md` — your operating rules and autonomy boundaries
2. Read `02-agent/rules/` — code quality, security, and autonomy constraints
3. Read `04-prompting/PROMPTING_GUIDE.md` — how the workflow operates
4. Read `04-prompting/LESSONS_LEARNED.md` — mistakes to avoid
5. Read `03-workflows/` — development, testing, deployment, troubleshooting procedures

**Only after absorbing the above**, begin the user-facing workflow:

---

## Workflow

### Phase A — YOU interview the user (they participate here)

**Step 1: Research** → Read `00-research/RESEARCH_GUIDE.md` and `00-research/COMPETITOR_ANALYSIS.md`. Interview the user about their idea — what problem they're solving, who it's for, what exists today. Fill out the research templates based on their answers.

**Step 2: Documentation** → Read each template in `01-docs/` in order (PRD → App Flow → Tech Stack → Frontend → Backend → Implementation Plan). For each, interview the user to gather requirements, then generate the filled document. The user reviews and refines each doc with you before moving on.

**Step 3: MCP Discovery** → Based on the tech stack chosen, recommend MCP servers that would benefit this project (e.g., Figma MCP for design, Firebase MCP for backend). See `02-agent/skills/MCP_SETUP.md`. Ask the user which ones to enable.

### Phase B — YOU work autonomously (user steps away)

**Step 4: Task Decomposition** → Break the Implementation Plan into a detailed, numbered task list. Each task should be self-contained with:
- Files to read for context
- Files to create/modify
- Success criteria (what "done" looks like)
- Verification commands to run

**Step 5: Build** → Execute each task from the list, following `02-agent/rules/` for code quality and `03-workflows/DEVELOPMENT.md` for git/commit practices. After each task, run verification (`tsc --noEmit`, tests, lint). If checks fail, iterate until they pass.

**Step 6: Harden & Ship** → Follow `03-workflows/PRODUCTION_HARDENING.md`, then run through `05-checklists/MVP_LAUNCH.md` and `05-checklists/APP_STORE.md` (if applicable).

---

## Key Rules

- **Never guess** — if a spec is ambiguous, ask the user
- **Docs are truth** — every implementation decision references `01-docs/`
- **Small steps** — implement, verify, commit, repeat
- **Learn from mistakes** — check `04-prompting/LESSONS_LEARNED.md` before implementing patterns that are known to cause issues
- **Self-anneal** — after each milestone, update docs to match reality
