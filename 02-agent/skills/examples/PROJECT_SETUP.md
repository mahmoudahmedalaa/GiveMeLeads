---
name: Project Setup
description: Initialize a new project from the template folder
---

# Project Setup

## When to Use
Starting a brand new project. Copies the template structure, fills in project-specific details, and verifies the foundation is ready.

## Prerequisites
- Template folder exists at the expected path
- Project name and type decided
- Target platform chosen (iOS / Android / Web / Cross-platform)

## Steps

1. **Copy template** to your new project directory
   ```bash
   cp -r template/ ~/Documents/Projects/[project-name]/
   ```

2. **Fill in Research** — Complete `00-research/RESEARCH_GUIDE.md` and `00-research/COMPETITOR_ANALYSIS.md`

3. **Generate documentation** — Use the AI prompts in each `01-docs/` template:
   - Start with `PRD.md` → defines WHAT to build
   - Then `APP_FLOW.md` → defines HOW users navigate
   - Then `TECH_STACK.md` → defines WHICH tools to use
   - Then `FRONTEND_GUIDELINES.md` + `BACKEND_STRUCTURE.md`
   - Finally `IMPLEMENTATION_PLAN.md` → defines build ORDER

4. **Customize AGENTS.md** — Update `02-agent/AGENTS.md` with:
   - Project name and version
   - Current roadmap
   - Any project-specific rules

5. **Initialize git**
   ```bash
   git init
   git add .
   git commit -m "Initial project setup from template"
   ```

6. **Initialize the codebase** — Follow `01-docs/IMPLEMENTATION_PLAN.md` Phase 1

## Rules
- Complete research BEFORE generating docs
- Generate docs in order (PRD → App Flow → Tech Stack → etc.)
- Pin all dependency versions — no "latest"
- Never commit `.env` files

## Verification
- [ ] All `01-docs/` files populated with project-specific content
- [ ] `02-agent/AGENTS.md` updated with project context
- [ ] Git initialized with first commit
- [ ] Project runs locally
- [ ] `.env` is in `.gitignore`
