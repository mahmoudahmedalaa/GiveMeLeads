# Phase 7: Deployment Prompts

## Pre-Deployment

```
Prepare for production deployment.

Complete these checklists:
1. 03-workflows/PRODUCTION_HARDENING.md — all items checked
2. 05-checklists/MVP_LAUNCH.md — all items checked
3. 05-checklists/APP_STORE.md — all metadata ready (if mobile)

Run verification:
- tsc --noEmit (zero errors)
- npm test (all pass)
- npm run lint (clean)
- Check all env vars are production values
- Confirm no debug tools accessible to users

Report status for each item.
```

## Build & Submit

```
Execute the deployment process following 03-workflows/DEPLOYMENT.md.

Platform: [iOS / Android / Web]
Build profile: [development / preview / production]

Steps:
1. Create git tag for this version
2. Run the build command
3. Monitor build output for errors
4. Submit to [App Store / Play Store / hosting]
5. Verify deployment successful

If the build fails, check 03-workflows/TROUBLESHOOTING.md for known issues.
```

## Post-Deploy Monitoring

```
The app has been deployed to production. Set up monitoring:

1. What to watch for the first 24 hours:
   - Crash rate (should be < 1%)
   - API error rate
   - User sign-up/sign-in success rate
   - Payment flow completion rate

2. Alert thresholds:
   - Crash rate > 2% → immediate investigation
   - API errors > 5% → check server logs
   - Auth failures spike → check provider status

3. Rollback criteria:
   - Any data loss scenario
   - Crash rate > 5%
   - Payment processing failures

Create a monitoring dashboard or report template for these metrics.
```
