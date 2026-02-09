# Implementation Plan & Build Sequence

> The exact order to build things. Each step is testable. No guessing what comes next.

## Overview

| Field | Value |
|:------|:------|
| **Project** | GiveMeLeads |
| **MVP Target** | 4-5 weeks from start |
| **Platform** | iOS (Swift / SwiftUI) |
| **Approach** | Documentation-first, iterative, test-after-every-step |

### Build Rules
1. Code follows documentation (not the reverse)
2. Test after every step — don't batch
3. Deploy to TestFlight after each milestone
4. Each step produces a verifiable result
5. **One task per conversation** — fresh AI context = maximum quality

---

## Phase 1: Foundation (Week 1, Days 1-2)

### Step 1.1 — Xcode Project Setup
**Duration**: 2 hours  
**Goal**: Running Xcode project with correct structure

- [ ] Create new Xcode project (iOS App, SwiftUI, Swift)
- [ ] Set up folder structure per `02-agent/AGENTS.md`
- [ ] Add all SPM dependencies from `TECH_STACK.md`
- [ ] Configure SwiftLint
- [ ] Set bundle ID, team, deployment target (iOS 17)
- [ ] Initialize git and make initial commit
- [ ] Verify: project builds and runs on Simulator

### Step 1.2 — Environment & Config
**Duration**: 1 hour  
**Goal**: Secrets and config properly managed

- [ ] Create `Config.xcconfig` for Supabase URL/key
- [ ] Create `Secrets.xcconfig` (gitignored) for API keys
- [ ] Set up `AppConfig.swift` to read config values
- [ ] Add `.gitignore` for Secrets, build artifacts
- [ ] Verify: app reads config values correctly

### Step 1.3 — Supabase Setup
**Duration**: 2 hours  
**Goal**: Supabase project created with schema applied

- [ ] Create Supabase project
- [ ] Apply database schema from `BACKEND_STRUCTURE.md`
- [ ] Enable Row Level Security on all tables
- [ ] Configure Supabase Auth (email + Apple)
- [ ] Test connection from iOS app
- [ ] Verify: can query empty tables from app

---

## Phase 2: Design System (Week 1, Days 3-4)

### Step 2.1 — Theme & Design Tokens
**Duration**: 2 hours  
**Goal**: All colors, fonts, spacing defined in code

- [ ] Create `Theme/` folder with `Colors.swift`, `Typography.swift`, `Spacing.swift`
- [ ] Implement all tokens from `FRONTEND_GUIDELINES.md`
- [ ] Register Poppins custom font
- [ ] Create gradient definitions
- [ ] Verify: preview shows correct colors/fonts

### Step 2.2 — Core Components
**Duration**: 4 hours  
**Goal**: Reusable component library

- [ ] `PrimaryButton.swift` — gradient, press animation, haptic
- [ ] `SecondaryButton.swift` — bordered variant
- [ ] `LeadCardView.swift` — swipeable card with score badge
- [ ] `ScoreBadge.swift` — colored circle with number
- [ ] `ChipView.swift` — keyword/subreddit tags
- [ ] `InputField.swift` — floating label, validation
- [ ] `LoadingView.swift` — skeleton screens
- [ ] `EmptyStateView.swift` — illustration + CTA
- [ ] Verify: all components render correctly in previews

---

## Phase 3: Authentication (Week 2, Days 5-6)

### Step 3.1 — Auth Flow
**Duration**: 3 hours  
**Goal**: User can sign up and log in

- [ ] Implement `AuthViewModel` with Supabase Auth
- [ ] Build `WelcomeScreen` (brand, CTA)
- [ ] Build `OnboardingScreen` (3 animated slides)
- [ ] Build `LoginScreen` (email/pass + Sign in with Apple)
- [ ] Build `SignUpScreen`
- [ ] Handle auth state changes (auto-navigate on login)
- [ ] Create user row in `users` table on signup
- [ ] Set trial_ends_at = signup + 7 days
- [ ] Verify: full signup → login → landing flow works

### Step 3.2 — Session & Navigation
**Duration**: 2 hours  
**Goal**: Navigation guards and session management

- [ ] Implement `AppRouter` for auth vs main navigation
- [ ] Set up `TabView` with 4 tabs (Leads, Keywords, Saved, Settings)
- [ ] Auto-redirect to auth when session expires
- [ ] Token auto-refresh via Supabase SDK
- [ ] Verify: closing/reopening app maintains session

---

## Phase 4: Core Features (Week 2-3)

### Step 4.1 — Keyword Tracking
**Duration**: 4 hours  
**Goal**: User can create profiles and add keywords

**Ref**: `PRD.md` Feature 1, `APP_FLOW.md` Keyword Management

- [ ] Create `KeywordViewModel` with CRUD operations
- [ ] Build `KeywordListScreen` — list profiles + keywords
- [ ] Build `AddKeywordSheet` — keyword input + validation
- [ ] Build `AddProfileSheet` — profile name + subreddits
- [ ] Implement profile toggle (on/off)
- [ ] Enforce limits (3 profiles, 10 keywords each)
- [ ] Verify: can create/edit/delete keywords, persists to Supabase

### Step 4.2 — Reddit Integration (Edge Function)
**Duration**: 4 hours  
**Goal**: Edge Function fetches Reddit posts for keywords

- [ ] Register Reddit API app (OAuth2)
- [ ] Build `scan-reddit` Edge Function
- [ ] Implement Reddit OAuth token flow (app-only auth)
- [ ] Search Reddit for each keyword
- [ ] Filter by subreddit if specified
- [ ] Insert leads into database (skip duplicates)
- [ ] Set up pg_cron to run every 30 minutes
- [ ] Verify: leads appear in database after function runs

### Step 4.3 — Lead Scoring (Edge Function)
**Duration**: 3 hours  
**Goal**: Every lead gets an AI intent score

**Ref**: `PRD.md` Feature 3, `BACKEND_STRUCTURE.md` score-lead

- [ ] Build `score-lead` Edge Function
- [ ] Implement heuristic scoring algorithm
- [ ] Trigger on lead INSERT via database webhook
- [ ] Store score + breakdown in lead row
- [ ] Verify: new leads get scored within 30 seconds

### Step 4.4 — Lead Discovery Feed
**Duration**: 5 hours  
**Goal**: Swipeable lead feed with scores

**Ref**: `PRD.md` Feature 2, `APP_FLOW.md` Lead Feed

- [ ] Create `LeadFeedViewModel` — fetch, filter, paginate
- [ ] Build `LeadFeedScreen` — scrollable card list
- [ ] Implement swipe gestures (right=save, left=dismiss)
- [ ] Add score-based color coding
- [ ] Implement pull-to-refresh
- [ ] Add filter sheet (score threshold, subreddit, keyword)
- [ ] Handle all states: loading, empty, error
- [ ] Verify: can browse, swipe, filter leads

### Step 4.5 — Lead Detail & AI Replies
**Duration**: 4 hours  
**Goal**: Full lead detail with AI engagement

**Ref**: `PRD.md` Feature 4, `APP_FLOW.md` Lead Detail

- [ ] Build `LeadDetailScreen` — full post, score breakdown
- [ ] Build `generate-replies` Edge Function
- [ ] Display AI reply suggestions (3 tones)
- [ ] Implement copy-to-clipboard
- [ ] "Open in Reddit" deep link
- [ ] Quick actions: save, dismiss, mark contacted
- [ ] Verify: can view detail, get replies, copy, open Reddit

---

## Phase 5: Monetization & Notifications (Week 3-4)

### Step 5.1 — Subscription (RevenueCat)
**Duration**: 3 hours  
**Goal**: $19/month subscription with 7-day trial

**Ref**: `PRD.md` Feature 5

- [ ] Set up RevenueCat project
- [ ] Configure product in App Store Connect ($19/mo)
- [ ] Build `PaywallScreen` — benefits, pricing, CTA
- [ ] Implement trial status checking
- [ ] Show paywall when trial expires
- [ ] Handle restore purchases
- [ ] Verify: trial → paywall → purchase flow works in sandbox

### Step 5.2 — Push Notifications
**Duration**: 3 hours  
**Goal**: Real-time alerts for high-score leads

**Ref**: `PRD.md` Feature 6

- [ ] Configure APNs in Xcode + Supabase
- [ ] Register for push notifications on app launch
- [ ] Send notification from Edge Function when lead scores ≥ threshold
- [ ] Deep link from notification → lead detail
- [ ] Implement notification settings (threshold, daily cap)
- [ ] Build `NotificationSettingsScreen`
- [ ] Verify: receiving notifications on device for high-score leads

---

## Phase 6: Settings & Polish (Week 4)

### Step 6.1 — Settings & Profile
**Duration**: 2 hours  
**Goal**: Account management and preferences

- [ ] Build `SettingsScreen` — all sections from `APP_FLOW.md`
- [ ] Build `ProfileScreen` — edit product description
- [ ] Build `SubscriptionScreen` — plan details, manage
- [ ] Implement sign out with confirmation
- [ ] Show trial countdown
- [ ] Verify: all settings screens functional

### Step 6.2 — Saved Leads Tab
**Duration**: 2 hours  
**Goal**: Dedicated saved leads collection

- [ ] Build `SavedLeadsScreen` — filtered lead list (status = saved/contacted)
- [ ] Implement lead status management
- [ ] Add lead count badges on tab
- [ ] Verify: saved leads appear, status updates persist

### Step 6.3 — Polish & Animations
**Duration**: 3 hours  
**Goal**: Premium feel

- [ ] Add all micro-animations from `FRONTEND_GUIDELINES.md`
- [ ] Implement haptic feedback
- [ ] Add skeleton loading screens
- [ ] Smooth all transitions
- [ ] Test and fix accessibility (VoiceOver, Dynamic Type)
- [ ] Verify: app feels polished and smooth

---

## Phase 7: Testing & Deployment (Week 4-5)

### Step 7.1 — Testing
**Duration**: 3 hours  
**Goal**: Critical paths covered

| Area | Target Coverage |
|:-----|:---------------|
| Auth logic | 80% |
| Keyword validation | 90% |
| Lead scoring algorithm | 90% |
| ViewModels | 70% |

- [ ] Set up XCTest framework
- [ ] Write auth flow tests
- [ ] Write keyword validation tests
- [ ] Write scoring heuristic tests
- [ ] Write ViewModel unit tests
- [ ] Verify: all tests pass

### Step 7.2 — TestFlight
**Duration**: 2 hours  
**Goal**: Beta build on TestFlight

- [ ] Configure signing and provisioning
- [ ] Archive and upload to App Store Connect
- [ ] Invite 10-20 beta testers
- [ ] Monitor crash reports
- [ ] Verify: app installs and runs on real device

### Step 7.3 — App Store Submission
**Duration**: 2 hours  
**Goal**: Submitted for review

- [ ] Complete `05-checklists/APP_STORE.md`
- [ ] Prepare screenshots (6.7" and 6.5")
- [ ] Write App Store description
- [ ] Set up privacy policy URL
- [ ] Submit for review
- [ ] Verify: submission accepted, awaiting review

---

## Milestones

| Milestone | Target | Deliverables |
|:----------|:-------|:-------------|
| **Foundation** | Week 1 | Project running, Supabase connected, design system |
| **Auth** | Week 2 | Signup, login, session, navigation |
| **Core Features** | Week 3 | Keywords, Reddit integration, lead feed, detail |
| **Monetization** | Week 4 | Subscription, notifications, settings |
| **Launch** | Week 5 | Tested, TestFlight, App Store submission |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|:-----|:-------|:-----------|
| Reddit API access denied | Critical | Use official API, stay within ToS, have fallback UI |
| Scope creep | High | Stick to PRD P0 only, say no to P1 features |
| Free AI quality too low | Medium | Heuristic scoring is solid; AI replies are bonus |
| App Store rejection | Medium | Follow all HIG, test IAP thoroughly |
| Build timeline slip | Medium | Cut P0 feature 6 (notifications) if behind |
