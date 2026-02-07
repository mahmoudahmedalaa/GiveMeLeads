# Implementation Plan & Build Sequence

> The exact order to build things. Each step is testable. No guessing what comes next.

## Overview

| Field | Value |
|:------|:------|
| **Project** | [App Name] |
| **MVP Target** | [Date] |
| **Approach** | Documentation-first, iterative, test-after-every-step |

### Build Rules
1. Code follows documentation (not the reverse)
2. Test after every step — don't batch
3. Deploy to staging after each milestone
4. Each step produces a verifiable result
5. **One task per conversation** — fresh AI context = maximum quality

---

## Task Decomposition (Fresh Context Strategy)

After all documentation is generated (Phases 1-6 below), the AI breaks this plan into a **numbered task list**. Each task is designed to be executed in a **fresh conversation** for maximum AI quality.

### Task Format
Each task must include:

```
## Task [N]: [Name]

### Context (read these files first)
- 01-docs/PRD.md — Feature [X]
- 01-docs/APP_FLOW.md — Screen [Y]
- 01-docs/TECH_STACK.md — Section [Z]

### What to Build
- [ ] Create [file/component]
- [ ] Implement [specific functionality]
- [ ] Connect to [dependency]

### Success Criteria
- [ ] tsc --noEmit passes
- [ ] Feature works on device/browser
- [ ] All states handled (loading, empty, error)

### Kickoff Prompt
> Read AGENTS.md, then execute this task. Reference the files listed
> in Context above. Iterate until all Success Criteria pass.
```

### Why Fresh Contexts?
- Full AI context window per task → better output quality
- No accumulated confusion from earlier mistakes
- Each task has all context it needs → no dependencies on chat history
- If one task goes wrong, it doesn't pollute the next

### How It Works
1. AI generates the full task list from this Implementation Plan
2. User opens a **new conversation** for each task
3. Pastes the task's kickoff prompt
4. AI reads the relevant docs and executes
5. AI iterates until all verification checks pass
6. User moves to next task in a new conversation

---

## Phase 1: Foundation

### Step 1.1 — Project Setup
**Duration**: 1 hour  
**Goal**: Running project with linting configured

- [ ] Initialize git repository
- [ ] Initialize project (framework-specific)
- [ ] Install all dependencies from `TECH_STACK.md` (exact versions)
- [ ] Configure linter + formatter
- [ ] Verify: project runs locally, no lint errors

### Step 1.2 — Environment Setup
**Duration**: 30 min  
**Goal**: All secrets and configs in place

- [ ] Create `.env` with all vars from `TECH_STACK.md`
- [ ] Create `.env.example` (no secrets)
- [ ] Add `.env` to `.gitignore`
- [ ] Verify: app reads env vars correctly

### Step 1.3 — Database / Backend Setup
**Duration**: 1 hour  
**Goal**: Database connected, schema applied

- [ ] Set up database (local or cloud)
- [ ] Configure connection
- [ ] Apply initial schema from `BACKEND_STRUCTURE.md`
- [ ] Verify: tables created, can query

---

## Phase 2: Design System

### Step 2.1 — Design Tokens
**Duration**: 1-2 hours  
**Goal**: Colors, fonts, spacing configured

- [ ] Apply all tokens from `FRONTEND_GUIDELINES.md`
- [ ] Test in a sample component
- [ ] Verify: custom styles work, no console errors

### Step 2.2 — Core Components
**Duration**: 3-4 hours  
**Goal**: Reusable component library

For each component from `FRONTEND_GUIDELINES.md`:
- [ ] Create component file
- [ ] Implement all variants and states
- [ ] Add TypeScript types
- [ ] Verify: all variants render correctly

---

## Phase 3: Authentication

### Step 3.1 — Auth Backend
**Duration**: 2-3 hours  
**Goal**: Register + Login endpoints working

- [ ] Implement registration (per `BACKEND_STRUCTURE.md`)
- [ ] Implement login with token generation
- [ ] Implement password hashing
- [ ] Test with API client (Postman/curl)
- [ ] Verify: can register, login, receive tokens

### Step 3.2 — Auth Frontend
**Duration**: 2-3 hours  
**Goal**: Registration and login UI connected

- [ ] Build registration screen (per `APP_FLOW.md`)
- [ ] Build login screen
- [ ] Connect to auth endpoints
- [ ] Handle validation, loading, error states
- [ ] Verify: end-to-end auth flow works

---

## Phase 4: Core Features

### Step 4.X — [Feature Name]
**Duration**: [estimate]  
**Goal**: [one-line description]

- [ ] Backend: Create endpoint(s) per `BACKEND_STRUCTURE.md`
- [ ] Frontend: Build UI per `APP_FLOW.md` + `FRONTEND_GUIDELINES.md`
- [ ] Connect frontend to backend
- [ ] Handle all states (loading, empty, error)
- [ ] Verify: feature works end-to-end

**Ref**: `PRD.md` Feature [N], `APP_FLOW.md` Screen [X]

<!-- Repeat Step 4.X for each P0 feature -->

---

## Phase 5: Testing

### Step 5.1 — Unit Tests
**Duration**: 2-3 hours  
**Goal**: Critical paths covered

| Area | Target Coverage |
|:-----|:---------------|
| Auth logic | 90% |
| Validation | 95% |
| Core features | 80% |

- [ ] Set up test framework
- [ ] Write auth tests
- [ ] Write validation tests
- [ ] Write core feature tests
- [ ] Verify: all tests pass

### Step 5.2 — Integration / E2E Tests
**Duration**: 3-4 hours  
**Goal**: Full user flows verified

- [ ] Registration → Login → Use Feature → Logout
- [ ] Error paths (wrong password, network failure)
- [ ] Verify: all flows pass on device/browser

---

## Phase 6: Deployment

### Step 6.1 — Staging Deploy
**Duration**: 1-2 hours

- [ ] Configure hosting (per `TECH_STACK.md`)
- [ ] Set production environment variables
- [ ] Deploy
- [ ] Smoke test all features
- [ ] Verify: fully functional on staging URL/device

### Step 6.2 — Production Launch
**Duration**: 1-2 hours

- [ ] Complete `05-checklists/MVP_LAUNCH.md`
- [ ] Complete `05-checklists/APP_STORE.md` (if applicable)
- [ ] Deploy to production
- [ ] Monitor error logs for 24 hours
- [ ] Verify: zero critical errors

---

## Milestones

| Milestone | Target | Deliverables |
|:----------|:-------|:-------------|
| **Foundation** | Week 1 | Project running, DB connected, design tokens |
| **Auth** | Week 2 | Register, login, session management |
| **Core Features** | Week 3 | All P0 features working |
| **MVP Launch** | Week 4 | Tested, deployed, monitoring |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|:-----|:-------|:-----------|
| Scope creep | High | Stick to PRD P0 only |
| Schema changes | High | Follow migration process |
| Auth bugs | Critical | Test extensively, use proven libraries |
| Performance | Medium | Implement caching early |
| Timeline slip | Medium | Build buffer, track daily |

---

## AI Generation Prompt

```
Create an Implementation Plan for [YOUR APP].

Context:
- MVP Timeline: [WEEKS]
- Team: [SOLO / TEAM SIZE]
- Tech Stack: [FROM TECH_STACK.md]
- Features: [P0 LIST FROM PRD.md]

Generate a phased build plan with:
1. PHASE 1 (Foundation): Project setup, env config, database
2. PHASE 2 (Design): Design tokens, core components
3. PHASE 3 (Auth): Backend endpoints, frontend screens
4. PHASE 4 (Features): One step per P0 feature with backend + frontend tasks
5. PHASE 5 (Testing): Unit tests + integration tests
6. PHASE 6 (Deploy): Staging → Production

For EACH step provide: duration estimate, task checklist, success criteria, doc references.
Include milestone timeline and risk mitigation table.
```
