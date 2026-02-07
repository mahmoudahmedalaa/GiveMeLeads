# Post-Launch Plan

> What happens after you ship. The first 30 days determine long-term success.

## Week 1: Monitor & Stabilize

### Daily Monitoring
- [ ] Check crash reports (Sentry/Crashlytics/App Store)
- [ ] Review error logs
- [ ] Monitor key metrics:
  - Crash-free rate (target: >99%)
  - Sign-up completion rate
  - Core feature usage rate
  - Payment conversion rate (if applicable)

### Respond to Issues
- **Critical crash** (>2% users affected) → Hotfix within 24 hours
- **Major bug** (core feature broken) → Fix within 48 hours
- **Minor bug** (cosmetic/edge case) → Queue for next update
- **User feedback** → Acknowledge within 24 hours

---

## Week 2-3: Learn & Iterate

### Gather Feedback
- [ ] Read all app store reviews
- [ ] Monitor support email
- [ ] Ask 3-5 users for direct feedback
- [ ] Identify top 3 pain points

### Plan v1.1
- [ ] Review P1 features from `01-docs/PRD.md`
- [ ] Prioritize based on user feedback + business impact
- [ ] Update roadmap in `02-agent/AGENTS.md`
- [ ] Create implementation plan for next version

---

## Week 4: Optimize & Grow

### Performance
- [ ] Review app load times
- [ ] Optimize slow screens / API calls
- [ ] Reduce bundle size if needed

### Growth
- [ ] Set up basic analytics (if not done)
- [ ] Identify top acquisition channels
- [ ] Plan marketing activities

### Documentation Update
- [ ] Update `04-prompting/LESSONS_LEARNED.md` with post-launch learnings
- [ ] Update `03-workflows/TROUBLESHOOTING.md` with new issues found
- [ ] Self-anneal `02-agent/AGENTS.md` based on reality vs. plan

---

## Ongoing Cadence

| Activity | Frequency |
|:---------|:----------|
| Check crash reports | Daily |
| Review user feedback | Weekly |
| Security patches | Monthly |
| Dependency updates | Monthly |
| Feature release | Bi-weekly or monthly |
| Full regression test | Before each release |
| Docs self-annealing | After each release |

---

## Version Planning Template

### v[X.Y] — [Theme/Codename]
**Target date**: [Date]  
**Focus**: [1-2 sentences]

| Feature | Priority | Status |
|:--------|:---------|:-------|
| | P0/P1/P2 | ⬜/🔄/✅ |

**Success criteria**:
- [ ] [Measurable outcome]
- [ ] [Measurable outcome]
