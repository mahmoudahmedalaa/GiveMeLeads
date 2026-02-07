# Security-First Principles

> Security is not a feature — it's a constraint on every feature. These rules apply to all code.

## Secrets Management

### Rules
- **Never** hardcode API keys, tokens, or passwords in source code
- **Never** commit `.env` files to git
- **Always** use environment variables for secrets
- **Always** create `.env.example` with placeholder values (not real secrets)

### Environment Variable Naming
```bash
# Format: SERVICE_PURPOSE
FIREBASE_API_KEY="..."
REVENUECAT_IOS_KEY="appl_..."
DATABASE_URL="postgresql://..."
```

### Verification
```bash
# Check for accidentally committed secrets
git log --all --diff-filter=A -- '*.env' '.env*'
grep -r "sk_live\|api_key\|password" src/ --include="*.ts" --include="*.tsx"
```

---

## Authentication Security

| Measure | Requirement |
|:--------|:------------|
| Password hashing | bcrypt, minimum 12 salt rounds |
| Token expiry | Access: 15 min, Refresh: 7 days |
| Email verification | Required before full access |
| Social auth | Clean slate login (sign out before sign in) |
| Session persistence | Explicit persistence configuration |

### Common Auth Pitfalls (from real experience)
1. **Firebase "Component not registered"** → Use Compat layer, not modular SDK in React Native
2. **Cross-provider conflicts** → Always `signOut()` before new provider sign-in
3. **Session lost on force-close** → Set persistence to LOCAL explicitly
4. **Social login silent failures** → Log the full credential object for debugging

---

## Production Hardening

### Pre-Release Checklist
- [ ] **Debug screens removed** — No dev tools accessible to users
- [ ] **Test toggles stripped** — No `isPro` overrides, no onboarding resets
- [ ] **Console logs guarded** — `if (__DEV__)` or removed entirely
- [ ] **Debug log levels** — Set to production level (e.g., `LOG_LEVEL.ERROR`)
- [ ] **Environment sync** — Using production keys, not sandbox/test keys
- [ ] **Error reporting** — Crash reporting enabled (Sentry, Crashlytics, etc.)

### Environment Parity
| Item | Development | Production |
|:-----|:------------|:-----------|
| API keys | Test/sandbox | Production |
| Database | Local/staging | Production |
| Log level | DEBUG | ERROR |
| Dev tools | Enabled | Removed |
| Analytics | Disabled | Enabled |

---

## Input Validation

### Client-Side
- Validate format before sending (email regex, min length)
- This is for UX only — never trust client validation for security

### Server-Side (source of truth)
- Validate all inputs again on the server
- Sanitize HTML to prevent XSS
- Enforce max lengths at DB level
- Use parameterized queries (ORM) to prevent SQL injection

---

## Rate Limiting

| Endpoint Type | Limit | Window |
|:-------------|:------|:-------|
| Login | 5 requests | 15 minutes |
| Registration | 3 requests | 1 hour |
| API (authenticated) | 100 requests | 1 minute |
| API (public) | 50 requests | 1 minute |
| File upload | 10 requests | 1 hour |

---

## Data Protection
- HTTPS only in production
- Encrypt sensitive data at rest
- Never return password hashes in API responses
- Log user actions but never log passwords or tokens
- Implement "Delete Account" feature (App Store requirement)
