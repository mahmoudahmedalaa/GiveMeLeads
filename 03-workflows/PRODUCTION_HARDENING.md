# Production Hardening

> The gap between "it works on my machine" and "it works for users." Complete this checklist before every release.

## 1. Debug Screen Stripping

| Item | Status |
|:-----|:-------|
| Developer tools section removed from Settings | [ ] |
| Onboarding reset button removed | [ ] |
| Pro status toggle / manual override removed | [ ] |
| Welcome screen reset shortcut removed | [ ] |
| Test/demo accounts removed from UI | [ ] |
| Any "skip verification" shortcuts removed | [ ] |

> **Rule**: Use physical deletion, not JSX comments. Commented-out code `{/* ... */}` can accidentally reappear during rapid edits.

---

## 2. Environment Sync

| Item | Status |
|:-----|:-------|
| All API keys are production (not sandbox/test) | [ ] |
| Database points to production | [ ] |
| Firebase config matches production project | [ ] |
| RevenueCat / payment keys are production | [ ] |
| Push notification tokens are production | [ ] |
| Bundle ID matches App Store Connect | [ ] |
| `.env` NOT committed to git | [ ] |

---

## 3. Log Cleaning

| Item | Status |
|:-----|:-------|
| All `console.log` guarded by `__DEV__` or removed | [ ] |
| SDK debug log levels set to production (e.g., `LOG_LEVEL.ERROR`) | [ ] |
| No sensitive data logged (tokens, passwords, user data) | [ ] |
| Error reporting SDK configured (Sentry, Crashlytics) | [ ] |

---

## 4. Build Verification

| Item | Status |
|:-----|:-------|
| `tsc --noEmit` passes with zero errors | [ ] |
| All import paths verified (no broken `../../` chains) | [ ] |
| No unused imports or dead code | [ ] |
| Bundle size within expected range | [ ] |
| App installs and launches without crash | [ ] |

### Common Build Issues
- **Broken import paths**: `src/data/remote/` referencing `../../firebase/config` instead of `../../infrastructure/firebase/config`
- **Missing exports**: Using `getDb()` when the module exports `db` constant
- **Member drift**: Test files using `entity.id` when domain uses `entity.number`

---

## 5. Feature Completion Audit

For each P0 feature:

| Feature | Works on Device | Tested with Real Data | Edge Cases Handled |
|:--------|:---------------|:---------------------|:-------------------|
| Auth | [ ] | [ ] | [ ] |
| [Feature 2] | [ ] | [ ] | [ ] |
| [Feature 3] | [ ] | [ ] | [ ] |
| Payment/Premium | [ ] | [ ] | [ ] |
| Settings | [ ] | [ ] | [ ] |

> **"Done" means**: Tested with real network/native services on a physical device. Code-read-only verification is not sufficient for UI or logic changes.

---

## 6. Navigation Flow Verification

| Checkpoint | Status |
|:-----------|:-------|
| First-time user lands on correct screen | [ ] |
| Returning user bypasses onboarding | [ ] |
| Unauthenticated user sees login | [ ] |
| Deep links route correctly | [ ] |
| Back button/gesture works everywhere | [ ] |

### Launch Gate Sequence
Verify the exact order:
```
App Launch → Welcome (first time only) → Onboarding → Auth → Home
```

---

## 7. UI Ghost Element Audit

When removing features, search the entire codebase for:
- Icon names (e.g., `radio-tower`, `access-point`)
- Feature context hooks (e.g., `useFeatureName`)
- Conditional renders in ALL layout modes (initial, sticky, inline)

> Features often have redundant UI paths for different scroll offsets. Missing one creates "ghost" buttons that don't do anything.
