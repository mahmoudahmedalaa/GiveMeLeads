# Lessons Learned

> What went wrong, what went right, and what to do differently next time. Update this after every project.

## 🔴 Things That Went Wrong

### 1. Starting to Code Before Documentation
**What happened**: Jumped into coding without a complete PRD or tech spec. Features were built based on chat conversations, leading to inconsistent implementations and rework.  
**Fix**: Never write code until `01-docs/PRD.md` and `01-docs/APP_FLOW.md` are complete and reviewed.

### 2. Mock-to-Real Transition Gap
**What happened**: Built the entire app with mock services (mock auth, mock payments). When switching to real Firebase/RevenueCat, everything broke – different return types, async behavior, error cases not handled.  
**Fix**: Use real services from day one, even if it means slower initial progress. Mock only for tests.

### 3. Firebase SDK Version Chaos
**What happened**: Used Firebase modular SDK (v9/v10) in React Native. Encountered persistent "Component not registered" errors, HMR crashes, and auth persistence failures.  
**Fix**: Use Firebase Compat Layer (`firebase/compat/app`) for React Native. It's more stable for singleton registration and native bridge requirements. Document this in `TROUBLESHOOTING.md`.

### 4. Debug Screens Shipped to Production
**What happened**: Left developer tools (onboarding reset, Pro toggle) in the Settings screen for the App Store submission.  
**Fix**: Use `PRODUCTION_HARDENING.md` checklist before every release. Physically delete debug code — never just comment it out.

### 5. Import Path Fragility
**What happened**: Refactored file structure but forgot to update import paths in some repositories. `tsc --noEmit` would have caught this, but wasn't run before the build.  
**Fix**: Run `tsc --noEmit` before every commit. Add it to pre-commit hooks.

### 6. AI Tool JSX Corruption
**What happened**: AI editing tools occasionally double-escaped string attributes in JSX (`mode=\\\"outlined\\\"`), causing syntax errors.  
**Fix**: When editing JSX, verify no backslashes appear before quotes. If tools consistently corrupt, use a Python script for literal string replacement.

---

## 🟢 Things That Went Right

### 1. Clean Architecture
Domain layer with zero framework dependencies made testing easy and refactoring safe.

### 2. Documentation-First Approach (When We Did It)
Features built from complete specs had fewer bugs and less rework than ad-hoc implementations.

### 3. The 3-Layer AGENTS.md
Having Directive (docs), Orchestration (AGENTS.md), and Execution (workflows/skills) gave AI agents clear boundaries and reduced hallucinations.

### 4. Production Readiness Audit
Systematic feature-by-feature audit before submission caught multiple issues that would have caused App Store rejection.

### 5. Comprehensive QA Document
Having a single `TROUBLESHOOTING.md` with categorized fixes prevented re-debugging the same issues.

---

## 📋 Rules to Carry Forward

1. **Research before code** — 1 hour of research saves 10 hours of rework
2. **Pin all versions** — "latest" is a timebomb
3. **Real services from day one** — mocks hide real-world complexity
4. **`tsc --noEmit` before every commit** — catches the bugs you can't see
5. **Physical deletion > comments** — commented code comes back to haunt you
6. **Delete Account feature** — App Store requires it. Build it early, not as an afterthought
7. **Test on real device** — simulator misses native module issues
8. **Self-anneal** — after every milestone, update docs to match reality

---

## ➕ Add Your Lessons Here

### [Project Name] — [Date]

**What went wrong**:  

**What went right**:  

**Rule to add**:  
