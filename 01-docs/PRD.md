# Product Requirements Document (PRD)

> The single source of truth for WHAT you're building and WHY. Every feature decision traces back to this document.

## 1. Overview

### Product Name
**GiveMeLeads**

### One-Line Description
A native iOS app that uses AI to find, score, and help you engage with high-intent leads from Reddit — on autopilot.

### Problem Statement
Businesses and solopreneurs waste 1-2 hours daily scrolling Reddit looking for people actively asking for products/services like theirs. They miss 90% of high-intent posts, and the most popular tool (GummySearch) shut down in Dec 2025, leaving 10K+ users with no mobile-first alternative.

### Target User
Solopreneurs, indie hackers, SaaS founders, and freelancers aged 25-40 who use Reddit as a sales channel and want AI-scored leads delivered to their iPhone with one-tap engagement.

---

## 2. Goals & Success Metrics

### Business Goals
| Goal | Metric | Target (MVP) |
|:-----|:-------|:-------------|
| User Acquisition | Downloads / Sign-ups | 1,000 downloads in first 60 days |
| Engagement | DAU / Session length | 40% DAU, 3-5 min avg session |
| Revenue | MRR / Conversion rate | $5,000 MRR / 15% trial→paid |
| Retention | D7 / D30 retention | 60% D7 / 40% D30 |

### User Goals
1. As a **solopreneur**, I want to **get notified of Reddit posts where people ask for my type of service** so that **I can respond before competitors do**
2. As a **SaaS founder**, I want to **see AI-scored leads ranked by purchase intent** so that **I focus my time on the highest-value opportunities**
3. As a **freelancer**, I want **AI-generated reply suggestions** so that **I can engage quickly without crafting every response from scratch**

---

## 3. Feature Prioritization

### P0 — Must Have for Launch
> Without these, the app has no value. Ship these or don't ship.

#### Feature 1: Keyword Tracking Setup
- **What**: Users create keyword tracking profiles to monitor specific terms on Reddit
- **User Story**: As a user, I want to set up keywords related to my business so that the app monitors Reddit for matching posts
- **Acceptance Criteria**:
  - [ ] User can add up to 10 keywords per profile
  - [ ] User can create up to 3 tracking profiles
  - [ ] Keywords validate (no empty, no duplicates, 2-50 chars)
  - [ ] User can select specific subreddits or use "all" 
  - [ ] User can toggle profiles on/off
  - [ ] User can edit/delete keywords and profiles
- **Edge Cases**:
  - Empty keyword list → show setup prompt
  - Keyword matches too broadly → warn user and suggest refinement
  - Special characters in keywords → sanitize but allow quotes for exact match

#### Feature 2: Lead Discovery Feed
- **What**: A real-time scrollable/swipeable feed of Reddit posts that match the user's keywords, sorted by AI relevance score
- **User Story**: As a user, I want to browse scored leads in a mobile-friendly feed so that I can quickly identify the best opportunities
- **Acceptance Criteria**:
  - [ ] Feed shows lead cards with: title, snippet, subreddit, score (0-100), time posted
  - [ ] Cards are color-coded by score (green ≥80, yellow 50-79, gray <50)
  - [ ] User can swipe right to save, left to dismiss
  - [ ] Pull-to-refresh fetches new leads
  - [ ] Filters: score threshold, subreddit, keyword, date range
  - [ ] Empty state with illustration when no leads found
  - [ ] Loading skeleton while fetching
- **Edge Cases**:
  - No matching posts → "No leads yet. Check back soon or broaden your keywords."
  - API rate limit hit → show cached leads with "Last updated X min ago" badge
  - Post deleted between discovery and viewing → graceful error with "Post no longer available"

#### Feature 3: AI Lead Scoring
- **What**: AI automatically analyzes each Reddit post and assigns a 0-100 intent score
- **User Story**: As a user, I want each lead scored by AI so that I can prioritize high-intent prospects
- **Acceptance Criteria**:
  - [ ] Every lead gets a score within 30 seconds of discovery
  - [ ] Score considers: purchase intent, urgency language, relevance to keyword
  - [ ] Score breakdown is visible on lead detail (why this score?)
  - [ ] Scoring uses a free/local AI model (no per-lead cost)
  - [ ] User can report inaccurate scores to improve quality
- **Edge Cases**:
  - AI service unavailable → score as 50 (neutral) with "Score pending" badge
  - Post in non-English → attempt scoring, show "Different language detected" note
  - Very short posts (<20 chars) → score as 30 with "Limited context" note

#### Feature 4: Lead Detail & Engagement
- **What**: Full view of a lead with original post content, AI reply suggestions, and quick actions
- **User Story**: As a user, I want to see the full post context and get AI reply suggestions so that I can engage effectively
- **Acceptance Criteria**:
  - [ ] Shows full post text, author, subreddit, upvotes, comment count
  - [ ] Generates 2-3 AI reply suggestions (professional, casual, helpful)
  - [ ] User can copy a reply to clipboard
  - [ ] "Open in Reddit" button deep-links to the original post
  - [ ] Quick actions: save, dismiss, mark as contacted
  - [ ] Lead status tracking (new → saved → contacted → converted)
- **Edge Cases**:
  - Very long post → truncate with "Show more" expansion
  - NSFW post → warn before showing content
  - AI reply generation fails → show "Couldn't generate suggestions. Try again."

#### Feature 5: Authentication & Trial
- **What**: User authentication with email/Apple ID and 7-day free trial
- **User Story**: As a user, I want to sign up quickly and try the app for free so that I can evaluate before paying
- **Acceptance Criteria**:
  - [ ] Sign up with email/password or Sign in with Apple
  - [ ] 7-day free trial starts automatically
  - [ ] Trial countdown visible in Settings
  - [ ] Paywall appears after trial expires (soft paywall — can still view but not interact)
  - [ ] Subscription at $19/month via Apple IAP
  - [ ] Restore purchases works
- **Edge Cases**:
  - User reinstalls → trial status persists via Supabase account
  - Payment fails → show error, allow retry
  - User cancels subscription → access until end of billing period

#### Feature 6: Push Notifications
- **What**: Real-time push notifications for high-score leads
- **User Story**: As a user, I want to get notified when a high-intent lead is found so that I can respond quickly
- **Acceptance Criteria**:
  - [ ] Notifications for leads scoring 80+
  - [ ] User can customize score threshold in settings
  - [ ] Notification shows: post title snippet + score
  - [ ] Tapping notification opens lead detail
  - [ ] User can mute notifications temporarily ("Do not disturb")
  - [ ] Max 10 notifications per day (to prevent fatigue)
- **Edge Cases**:
  - Notifications disabled at OS level → show in-app prompt
  - Many high-score leads at once → batch into summary notification

---

### P1 — Should Have (v1.1)
> Important but not blocking launch. Plan for the first update.

| Feature | User Story | Complexity |
|:--------|:-----------|:-----------|
| Analytics dashboard | As a user, I want to see my lead stats so I can track performance | Medium |
| Saved leads collection | As a user, I want a dedicated saved leads section for easy access | Low |
| Custom AI instructions | As a user, I want to tell the AI about my product for better replies | Medium |
| Subreddit recommendations | As a user, I want AI to suggest relevant subreddits to monitor | Low |
| Lead export (CSV) | As a user, I want to export my leads for CRM import | Low |

---

### P2 — Nice to Have (Future)
> Ideas for later. Don't let these creep into the MVP scope.

| Feature | User Story | When |
|:--------|:-----------|:-----|
| X (Twitter) monitoring | Monitor Twitter for leads | v1.2 |
| LinkedIn monitoring | Monitor LinkedIn for leads | v2.0 |
| Web companion dashboard | View leads on desktop | v1.2 |
| Team collaboration | Share leads with team members | v2.0 |
| CRM integrations | Sync with HubSpot, Salesforce | v2.0 |
| Auto-reply posting | Post replies directly from app | v2.0 |

---

### Out of Scope
> Explicitly listing what you are NOT building prevents scope creep.

- ❌ Web application or dashboard (iOS only for MVP)
- ❌ X/Twitter or LinkedIn monitoring (Reddit only for MVP)
- ❌ Direct posting replies to Reddit (copy-to-clipboard only)
- ❌ Team management or multi-seat plans
- ❌ CRM integrations
- ❌ Android app
- ❌ Browser extension

---

## 4. User Scenarios

### Scenario 1: First-Time User
1. User downloads GiveMeLeads from App Store
2. Opens app → sees animated onboarding (3 slides: Discover → Score → Engage)
3. Taps "Get Started" → Sign in with Apple
4. Trial activates (7 days free)
5. Guided setup: "What do you offer?" → enters keywords (e.g., "project management tool", "task app recommendation")
6. Selects subreddits or uses "Auto-discover"
7. Sees first leads appear within 60 seconds
8. **Success**: User has a scored, filterable lead feed populated with Reddit posts

### Scenario 2: Returning User (Daily Use)
1. Receives push notification: "🎯 Score 92: Someone on r/SaaS is asking for project management tools"
2. Taps notification → sees full post + AI reply suggestions
3. Copies AI-suggested reply → opens Reddit to paste
4. Marks lead as "Contacted" → returns to feed
5. Swipes through 3-4 more leads (save best, dismiss rest)
6. **Success**: User engaged with 2-3 high-intent leads in under 5 minutes

### Scenario 3: Power User / Premium
1. Opens app → checks Analytics tab
2. Sees: "47 leads this week, 12 saved, 5 contacted, avg score 73"
3. Adjusts keyword for better targeting
4. Adds a new tracking profile for a second product
5. Reviews saved leads collection → exports to CSV
6. **Success**: User has data-driven insight into their Reddit lead gen performance

---

## 5. Technical Constraints

| Constraint | Decision | Rationale |
|:-----------|:---------|:----------|
| Offline support | Limited — cached leads viewable | Leads require live data, cache for reading |
| Min OS version | iOS 17+ | SwiftUI improvements, modern APIs |
| Auth method | Email/Password + Sign in with Apple | Apple requires SiWA for IAP apps |
| Data storage | Cloud (Supabase) + local cache (SwiftData) | Real-time sync + offline reading |
| Monetization | Subscription ($19/mo, 7-day trial) | Recurring revenue, Apple IAP |
| AI model | Free (on-device or free API tier) | No per-lead costs |

---

## 6. Launch Strategy

### MVP Scope
- **Features**: P0 only (6 features above)
- **Platforms**: iOS only
- **Timeline**: 4-5 weeks
- **Distribution**: App Store (TestFlight for beta → public release)

### Launch Checklist
- [ ] All P0 features tested on real device (iPhone 15)
- [ ] Privacy policy published
- [ ] App Store metadata prepared (screenshots, description, keywords)
- [ ] Analytics configured (TelemetryDeck or similar privacy-first)
- [ ] Support email set up
- [ ] 10-20 beta testers on TestFlight
- [ ] Landing page with App Store link
