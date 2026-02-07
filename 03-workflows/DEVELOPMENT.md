# Development Workflow

> How to work on this project day-to-day. Git, branching, commits, and code review.

## Git Branching Strategy

```
main (production)
  └── develop (staging)
       ├── feature/user-auth
       ├── feature/quran-reader
       ├── fix/login-crash
       └── hotfix/security-patch
```

### Branch Naming
| Type | Pattern | Example |
|:-----|:--------|:--------|
| Feature | `feature/short-description` | `feature/user-auth` |
| Bug fix | `fix/short-description` | `fix/login-crash` |
| Hotfix | `hotfix/short-description` | `hotfix/security-patch` |
| Refactor | `refactor/short-description` | `refactor/auth-context` |

---

## Commit Conventions

### Format
```
type: short description

[optional body with context]
```

### Types
| Type | When |
|:-----|:-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change that doesn't add feature or fix bug |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Build config, dependencies, tooling |
| `style` | Formatting, whitespace (no logic change) |

### Examples
```
feat: add email verification flow
fix: resolve crash on login with unverified email
refactor: extract auth logic into AuthContext
docs: update README with setup instructions
```

---

## Daily Workflow

1. **Pull latest** from `develop`
2. **Create branch** from `develop`
3. **Implement** in small, testable chunks
4. **Test** after each chunk
5. **Commit** with conventional message
6. **Push** and create PR
7. **Review** → merge to `develop`
8. **Deploy** `develop` to staging for verification

---

## Code Review Checklist

Before merging any PR:

- [ ] TypeScript compiles (`tsc --noEmit`)
- [ ] Tests pass (`npm test`)
- [ ] No lint errors (`npm run lint`)
- [ ] No `console.log` outside `__DEV__` guards
- [ ] Error states handled
- [ ] Matches the relevant doc (PRD, APP_FLOW, etc.)
- [ ] No secrets in code
- [ ] Accessibility maintained

---

## Local Development

### First-Time Setup
```bash
git clone [repo-url]
cd [project]
npm install
cp .env.example .env    # Fill in local values
npm run dev
```

### Daily Commands
```bash
npm run dev              # Start dev server
npm test                 # Run tests
npm run lint             # Check code quality
npx tsc --noEmit         # Type check
```

---

## Iterative Build Loop

> For mechanical implementation tasks, the AI should iterate autonomously until all checks pass. This is the "Ralph Wiggum Loop" — persistent, self-correcting automation.

### How It Works

```
┌─────────────────────────────────────────┐
│  AI receives task + success criteria    │
│              │                          │
│              ▼                          │
│  ┌──── Implement ◄──────────────┐      │
│  │          │                    │      │
│  │          ▼                    │      │
│  │   Run verification:          │      │
│  │   • tsc --noEmit             │      │
│  │   • npm test                 │      │
│  │   • npm run lint             │      │
│  │          │                    │      │
│  │     Pass? ─── No ──► Fix ───►│      │
│  │          │                          │
│  │         Yes                         │
│  │          │                          │
│  │          ▼                          │
│  │     Task Complete                   │
│  │     Commit + move to next           │
│  └─────────────────────────────────────│
└─────────────────────────────────────────┘
```

### Guardrails (required for safe iteration)
- ✅ TypeScript strict mode — catches type errors automatically
- ✅ Test suite — catches logic regressions
- ✅ Linting — catches style/quality issues
- ✅ Clear success criteria per task — AI knows when to stop
- ✅ Git commits after each passing task — easy rollback

### When to Use It
| Scenario | Use Loop? |
|:---------|:----------|
| Implementing a feature from a clear spec | ✅ Yes |
| Writing tests for existing code | ✅ Yes |
| Fixing a bug with clear repro steps | ✅ Yes |
| Architectural decisions | ❌ No — ask the user |
| Adding new dependencies | ❌ No — ask the user |
| Anything not in the docs | ❌ No — ask the user |

### Stop Conditions
The AI should stop iterating and ask for help if:
- 3+ failed attempts on the same error
- The fix requires changing files outside the task scope
- The error suggests a spec/architecture issue (not a code issue)
