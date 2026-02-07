# Product Requirements Document (PRD)

> The single source of truth for WHAT you're building and WHY. Every feature decision traces back to this document.

## 1. Overview

### Product Name
<!-- Your app name -->

### One-Line Description
<!-- What it does in one sentence — the "elevator pitch" -->

### Problem Statement
<!-- What specific problem does this solve? Be concrete, not abstract. -->

### Target User
<!-- Who is this for? Use the persona from your Research Guide. -->

---

## 2. Goals & Success Metrics

### Business Goals
| Goal | Metric | Target (MVP) |
|:-----|:-------|:-------------|
| User Acquisition | Downloads / Sign-ups | |
| Engagement | DAU / Session length | |
| Revenue | MRR / Conversion rate | |
| Retention | D7 / D30 retention | |

### User Goals
1. As a [user], I want to [action] so that [outcome]
2. 
3. 

---

## 3. Feature Prioritization

### P0 — Must Have for Launch
> Without these, the app has no value. Ship these or don't ship.

#### Feature 1: [Name]
- **What**: 
- **User Story**: As a [user], I want to [action] so that [outcome]
- **Acceptance Criteria**:
  - [ ] 
  - [ ] 
- **Edge Cases**:
  - 

#### Feature 2: [Name]
<!-- Same structure -->

---

### P1 — Should Have (v1.1)
> Important but not blocking launch. Plan for the first update.

| Feature | User Story | Complexity |
|:--------|:-----------|:-----------|
| | | Low/Med/High |

---

### P2 — Nice to Have (Future)
> Ideas for later. Don't let these creep into the MVP scope.

| Feature | User Story | When |
|:--------|:-----------|:-----|
| | | v1.2 / v2.0 |

---

### Out of Scope
> Explicitly listing what you are NOT building prevents scope creep.

- 
- 

---

## 4. User Scenarios

### Scenario 1: First-Time User
1. User downloads app from [Store]
2. Opens app → sees [welcome/onboarding]
3. [Steps through the first experience]
4. Reaches the core feature
5. **Success**: [What "done" looks like]

### Scenario 2: Returning User
1. Opens app
2. [Primary use case flow]
3. **Success**: [Outcome]

### Scenario 3: Power User / Premium
1. [Premium-specific flow]
2. **Success**: [Outcome]

---

## 5. Technical Constraints

| Constraint | Decision | Rationale |
|:-----------|:---------|:----------|
| Offline support | Required / Optional / None | |
| Min OS version | iOS 16+ / Android 12+ | |
| Auth method | Email / Social / Anonymous | |
| Data storage | Cloud / Local / Hybrid | |
| Monetization | Free / Freemium / Paid | |

---

## 6. Launch Strategy

### MVP Scope
- **Features**: P0 only
- **Platforms**: [iOS / Android / Both / Web]
- **Timeline**: [Target date]
- **Distribution**: [App Store / TestFlight / Web URL]

### Launch Checklist
- [ ] All P0 features tested on real device
- [ ] Privacy policy published
- [ ] App Store metadata prepared
- [ ] Analytics/crash reporting configured
- [ ] Support email set up

---

## AI Generation Prompt

```
Create a detailed Product Requirements Document (PRD) for my app.

App Concept: [DESCRIBE IN 3-5 SENTENCES]
Target User: [WHO IS THIS FOR - AGE, OCCUPATION, TECH LEVEL]
Platform: [iOS / Android / Web / Cross-platform]
Monetization: [Free / Freemium / Subscription / One-time]
MVP Timeline: [WEEKS AVAILABLE]

Generate the PRD with:

1. OVERVIEW: One-line description, problem statement, target user
2. GOALS & METRICS: Business goals with measurable targets, user goals as stories
3. FEATURES:
   - P0 (Must Have): 4-6 core features with acceptance criteria
   - P1 (Should Have): 3-5 features for v1.1
   - P2 (Nice to Have): Future ideas
   - Out of Scope: What we're explicitly NOT building
4. USER SCENARIOS: 3 detailed walkthroughs (new user, returning user, power user)
5. TECHNICAL CONSTRAINTS: Offline needs, auth, storage, minimum OS
6. LAUNCH STRATEGY: Scope, timeline, distribution

CRITICAL: Be specific. No vague features like "great UX." Every feature needs:
- Clear user story
- Testable acceptance criteria
- Complexity estimate (Low/Med/High)
```
