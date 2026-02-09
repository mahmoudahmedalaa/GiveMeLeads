# Deployment Procedures

> Build, deploy, and rollback. No surprises.

## Environments

| Environment | Purpose | Branch | URL |
|:------------|:--------|:-------|:----|
| **Development** | Local coding | feature/* | localhost |
| **Staging** | Testing before release | develop | staging URL |
| **Production** | Live users | main | production URL |

---

## Mobile App Deployment (Local Xcode)

> **Always use local Xcode builds.** Never use EAS Build or other paid cloud build services. See `XCODE_GUIDE.md` for full details.

### Quick Test on Your Phone (Debug)
```bash
# Plug iPhone in via USB
open ios/YourApp.xcworkspace
# In Xcode: Select your iPhone → Press Cmd+R
```

### Production Build (TestFlight / App Store)
```bash
# One command — builds, signs, exports IPA
./build-ios.sh
```

### Upload to TestFlight
```
Xcode → Window → Organizer → Select archive → Distribute App
→ App Store Connect → Upload
```

### Submit to App Store
```
App Store Connect → Your App → Add Build → Submit for Review
```

### Over-the-Air Updates (JS only)
```bash
# For JS-only changes (no native module additions)
eas update --branch production --message "Bug fix: [description]"
```

> ⚠️ OTA updates only work for JavaScript changes. Native module additions require a full build via `./build-ios.sh`.

---

## Web App Deployment

### Vercel (Recommended)
```bash
# Deploy to preview
vercel

# Deploy to production
vercel --prod
```

### Manual Build
```bash
npm run build
npm run start  # Verify locally before deploying
```

---

## Pre-Deployment Checklist

Before ANY production deployment:

- [ ] All tests pass
- [ ] `tsc --noEmit` has no errors
- [ ] No `console.log` statements (use `__DEV__` guards)
- [ ] Production environment variables set
- [ ] Debug tools stripped (see `PRODUCTION_HARDENING.md`)
- [ ] Staging tested end-to-end
- [ ] Build number incremented in `Info.plist`
- [ ] Git tag created for the version

---

## Rollback Plan

### Mobile
1. If caught before review: cancel in App Store Connect
2. If live: submit a hotfix build immediately
3. For JS issues: push OTA update reverting the change

### Web
1. Revert to previous deployment in Vercel/hosting dashboard
2. Or: `git revert HEAD && git push` → auto-deploys previous version

### Database
1. Never run destructive migrations without a backup
2. Keep migration rollback scripts
3. Test rollbacks on staging first

---

## Post-Deploy Monitoring

After every production deployment, monitor for 24 hours:

- [ ] Error tracking dashboard (Sentry, Crashlytics)
- [ ] App Store crash reports
- [ ] User feedback channels
- [ ] Server/function logs
- [ ] Performance metrics (load times, API latency)
