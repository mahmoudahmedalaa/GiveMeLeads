# AGENTS.md — Project Master Plan

> The operating system for AI agents working on this project. Read this FIRST before touching any code.

## Architecture: 3 Layers

```
┌─────────────────────────────────────┐
│  DIRECTIVE LAYER — What to build    │
│  01-docs/ (PRD, Tech Stack, etc.)   │
├─────────────────────────────────────┤
│  ORCHESTRATION — How to decide      │
│  This file (AGENTS.md)              │
├─────────────────────────────────────┤
│  EXECUTION — Doing the work         │
│  03-workflows/, 02-agent/skills/    │
└─────────────────────────────────────┘
```

- **Directive** → `01-docs/` — WHAT to build, WHY, and with WHAT technology
- **Orchestration** → This file — HOW to make decisions, WHEN to ask, autonomy rules
- **Execution** → `03-workflows/` + `02-agent/skills/` — Deterministic procedures and reusable skills

---

## Project Context

| Field | Value |
|:------|:------|
| **App Name** | GiveMeLeads |
| **Version** | 0.1.0 (MVP) |
| **Platform** | iOS (Swift / SwiftUI) |
| **Status** | Planning |
| **Architecture** | MVVM + Clean Architecture |
| **Backend** | Supabase (PostgreSQL + Edge Functions + Auth) |
| **AI** | Free models (on-device CoreML or free API tier) |
| **Target** | iOS 17+ |

---

## Operating Principles

> ⚠️ **MANDATORY**: Read `02-agent/skills/DEVELOPMENT_PRINCIPLES.md` before starting ANY work.
> It contains 7 non-negotiable principles from the project owner covering: free-only services,
> extensive testing, clean code, git discipline, beautiful UI, package usage, and approval requirements.

### 1. Plan Before You Code
- Read relevant docs from `01-docs/` before implementing
- Outline your approach, then build
- If the approach changes, update the docs

### 2. Small, Verifiable Steps
- Each change should be testable in isolation
- Commit after each working milestone
- Never make 500-line changes without intermediate verification

### 3. Document What You Learn
- Found a bug? Add it to `04-prompting/LESSONS_LEARNED.md`
- Discovered a pattern? Add it to `02-agent/rules/`
- Created a reusable procedure? Add it to `03-workflows/`

### 4. Never Guess
- If a spec is ambiguous → ASK the user
- If a dependency version is unclear → CHECK `01-docs/TECH_STACK.md`
- If a flow is undefined → CHECK `01-docs/APP_FLOW.md`

---

## Autonomy Protocol

### ✅ Act Autonomously
- Bug fixes that don't change behavior
- Implementing features clearly specified in the docs
- Running tests, linting, formatting
- Following established patterns in the codebase
- Adding error handling to existing code

### ⚠️ Summarize Then Act
- Refactoring that changes multiple files
- Adding new Swift packages
- Modifying database schema
- Changing authentication logic

### 🛑 Ask Before Acting
- Deleting files or features
- Changing the tech stack
- Architectural decisions not covered in docs
- Anything involving production data
- Security-sensitive changes
- Scope changes beyond the PRD

---

## File Organization

```
GiveMeLeads/
├── 00-research/          # Market research & competitor analysis
├── 01-docs/              # Source of truth for all decisions
├── 02-agent/             # AI agent rules and skills
│   ├── AGENTS.md         # This file
│   ├── rules/            # Constraints and standards
│   └── skills/           # Reusable procedures
├── 03-workflows/         # Dev, test, deploy procedures
├── 04-prompting/         # Prompting guide and templates
├── 05-checklists/        # Launch and post-launch checklists
└── GiveMeLeads/          # Xcode project root
    ├── App/              # App entry point, configuration
    ├── Core/             # Shared utilities, extensions, constants
    ├── Domain/           # Business logic layer
    │   ├── Entities/     # Data models
    │   ├── UseCases/     # Business rules
    │   └── Repositories/ # Protocol definitions
    ├── Data/             # Data access layer
    │   ├── Repositories/ # Repository implementations
    │   ├── DataSources/  # API + local data sources
    │   └── Models/       # DTO / API response models
    ├── Presentation/     # UI layer (SwiftUI)
    │   ├── Screens/      # Full-screen views
    │   ├── Components/   # Reusable UI components
    │   ├── ViewModels/   # MVVM view models
    │   └── Theme/        # Design system (colors, fonts, spacing)
    └── Infrastructure/   # Framework glue (Supabase, Notifications)
```

---

## Current Roadmap

### v0.1.0 — "MVP / GummySearch Replacement"
| Feature | Status | Priority |
|:--------|:-------|:---------|
| Keyword Tracking | ⬜ Not Started | P0 |
| Lead Discovery Feed | ⬜ Not Started | P0 |
| AI Lead Scoring | ⬜ Not Started | P0 |
| Lead Detail & Engagement | ⬜ Not Started | P0 |
| Auth & Trial | ⬜ Not Started | P0 |
| Push Notifications | ⬜ Not Started | P0 |

### v1.1 — "Insights"
| Feature | Status | Priority |
|:--------|:-------|:---------|
| Analytics Dashboard | ⬜ Not Started | P1 |
| Saved Leads Collection | ⬜ Not Started | P1 |
| Custom AI Instructions | ⬜ Not Started | P1 |
| Subreddit Recommendations | ⬜ Not Started | P1 |
| Lead Export (CSV) | ⬜ Not Started | P1 |

---

## Error Recovery Protocol

When something breaks:

1. **Read the error** — actually read it, don't just fix the symptom
2. **Check `03-workflows/TROUBLESHOOTING.md`** — might be a known issue
3. **Isolate** — is it build-time, runtime, or deployment?
4. **Fix, don't patch** — address root cause, not just the error message
5. **Document** — add the fix to `TROUBLESHOOTING.md` or `LESSONS_LEARNED.md`

---

## Self-Annealing

After every major milestone, update:
- [ ] `01-docs/` if specs drifted from reality
- [ ] `03-workflows/TROUBLESHOOTING.md` with new issues found
- [ ] `04-prompting/LESSONS_LEARNED.md` with what went wrong and right
- [ ] This file (`AGENTS.md`) if project context changed
