# MVP Launch Checklist

> Go/no-go decision. Every item must be checked before releasing to users.

## Feature Completeness

- [ ] All P0 features from `01-docs/PRD.md` implemented
- [ ] All user flows from `01-docs/APP_FLOW.md` tested on real device
- [ ] UI matches `01-docs/FRONTEND_GUIDELINES.md` specs
- [ ] API matches `01-docs/BACKEND_STRUCTURE.md` contracts

## Code Quality

- [ ] `tsc --noEmit` — zero errors
- [ ] `npm run lint` — zero warnings
- [ ] `npm test` — all tests pass
- [ ] No `console.log` outside `__DEV__` guards
- [ ] No TODO/FIXME comments in shipped code

## Security (from `02-agent/rules/SECURITY.md`)

- [ ] No secrets in source code
- [ ] `.env` in `.gitignore`
- [ ] All API keys are production values
- [ ] Password hashing configured (bcrypt 12+ rounds)
- [ ] Rate limiting in place
- [ ] Input validation on server-side
- [ ] HTTPS enforced

## Production Hardening (from `03-workflows/PRODUCTION_HARDENING.md`)

- [ ] Debug screens stripped
- [ ] Dev tools / toggles removed
- [ ] Log levels set to production
- [ ] Error reporting enabled (Sentry/Crashlytics)
- [ ] Bundle ID verified

## Infrastructure

- [ ] Database backed up
- [ ] Environment variables set in production
- [ ] CI/CD pipeline configured (if applicable)
- [ ] Monitoring/alerting configured
- [ ] Rollback plan documented

## User-Facing

- [ ] Privacy policy published and linked
- [ ] Terms of service published (if applicable)
- [ ] Support email set up
- [ ] App screenshots current (if app store)
- [ ] "Delete Account" feature implemented (App Store requirement)

## Final Verification

- [ ] Fresh install test — app works from zero state
- [ ] Auth flow — register, verify, login, logout, login again
- [ ] Core feature — full happy path on real device
- [ ] Payment flow — sandbox purchase completes (if applicable)
- [ ] Offline behavior — handles gracefully (if applicable)

## Decision

**GO** / **NO-GO** — Date: ___  
**Blocking issues**: ___  
**Ship version**: ___
