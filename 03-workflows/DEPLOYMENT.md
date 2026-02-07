# Deployment Procedures

> Build, deploy, and rollback. No surprises.

## Environments

| Environment | Purpose | Branch | URL |
|:------------|:--------|:-------|:----|
| **Development** | Local coding | feature/* | localhost |
| **Staging** | Testing before release | develop | staging URL |
| **Production** | Live users | main | production URL |

---

## Mobile App Deployment (EAS / Expo)

### Development Build
```bash
# Build for testing on physical device
eas build --profile development --platform ios
eas build --profile development --platform android
```

### Staging / Preview Build
```bash
eas build --profile preview --platform ios
```

### Production Build
```bash
# Build for App Store submission
eas build --profile production --platform ios
eas build --profile production --platform android
```

### Submit to App Store
```bash
eas submit --platform ios
eas submit --platform android
```

### Over-the-Air Updates (JS only)
```bash
# For JS-only changes (no native module additions)
eas update --branch production --message "Bug fix: [description]"
```

> ⚠️ OTA updates only work for JavaScript changes. Native module additions require a full build.

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
