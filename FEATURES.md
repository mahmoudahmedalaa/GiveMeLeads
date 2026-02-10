# GiveMeLeads — Feature Documentation

> **Latest stable version** — February 11, 2026

## What Is GiveMeLeads?

An iOS app that scans Reddit for people actively looking for products like yours and turns them into actionable sales leads — with AI-powered insights on WHY each lead matters and HOW to engage.

---

## Core Features

### 1. Product Profile Setup
- Describe your product in plain English
- AI analyzes your description using Apple's NaturalLanguage framework
- Auto-generates relevant keywords, subreddits, and search queries
- Supports 25+ category patterns (SaaS, religion, parenting, travel, music, sports, etc.)

### 2. Reddit Intelligence Engine
- Searches both **posts** and **comments** across targeted subreddits
- **25+ intent detection patterns** including:
  - Direct requests: "looking for", "need a", "recommend me"
  - Wish/desire signals: "I wish", "if only", "is there a"
  - Switching signals: "alternative to", "switch from", "tired of" (highest value)
- Quality gate at score ≥ 35 (fewer leads, every one worth reading)

### 3. Lead Intelligence (per lead)
Each lead comes with 3 pieces of actionable intelligence:

| Field | Purpose |
|-------|---------|
| **✨ Relevance Insight** | WHY this lead matters to you |
| **📝 Matching Snippet** | The exact sentence that triggered the match |
| **💡 Suggested Approach** | HOW to engage (specific, actionable guidance) |

### 4. Profile-Aware Lead Feed
- **Profile selector** — pill bar at top to switch between product profiles
- **Per-profile scanning** — scan targets ONE selected profile's keywords
- **Profile switching** — clears old leads, loads the new profile's results
- **Re-scan detection** — shows "✅ You're up to date!" if no new posts found
- **Clear results** — trash button removes unsaved leads for current profile

### 5. Lead Detail Screen
5-section action-oriented layout:
1. **Why This Lead Matters** — insight text + score bars (Intent/Fit/Urgency)
2. **Key Snippet** — the exact sentence, styled as a highlighted quote
3. **Suggested Approach** — actionable engagement guidance
4. **Original Post** — full Reddit post content
5. **Actions** — Open in Reddit, Generate AI Reply, Save, Dismiss, Mark Contacted

### 6. AI Reply Generation
- Choose tone: Professional, Casual, or Helpful
- AI generates a contextual reply based on the lead content
- Copy to clipboard and paste directly into Reddit
- Offline fallback templates when Edge Function is unavailable

### 7. Keyword Management
- Organized into tracking profiles
- Add/remove keywords per profile
- Scan individual profiles from the Keywords tab
- Toggle profiles active/inactive

### 8. Authentication
- Sign in with Apple
- Email magic link
- Secure session management via Supabase Auth

---

## Scoring System

| Component | Weight | What It Measures |
|-----------|--------|------------------|
| Intent | 40% | Is the person looking for a solution? |
| Urgency | 30% | How soon do they need it? |
| Fit | 30% | Does this match your product? |

**Score tiers:**
- 🟢 ≥ 80: Hot lead — high-intent buyer
- 🟡 50-79: Warm lead — worth engaging
- 🟠 35-49: Cool lead — monitor

---

## Tech Stack

- **iOS**: SwiftUI, Swift Observation framework
- **Backend**: Supabase (Postgres, Auth, Edge Functions)
- **NLP**: Apple NaturalLanguage framework for keyword extraction
- **API**: Reddit JSON API (posts + comments)
- **AI**: Supabase Edge Functions for reply generation

---

## Database Schema (key tables)

- `users` — auth profiles, subscription status
- `tracking_profiles` — product profiles with subreddit lists
- `keywords` — tracked keywords linked to profiles
- `leads` — discovered leads with scores, intelligence fields, profile_id
- `ai_replies` — generated reply suggestions

---

## Architecture

```
App/
├── RootView → AuthGate → MainTabView
├── Data/
│   ├── Services/ (ProductAnalyzer, RedditSearchService)
│   └── Repositories/ (LeadRepository, KeywordRepository, etc.)
├── Domain/
│   ├── Entities/ (Lead, TrackingProfile, Keyword, etc.)
│   └── Repositories/ (Protocols)
└── Presentation/
    ├── Theme/ (AppColors, AppTypography, AppSpacing)
    ├── Components/ (LeadCardView, ScoreBadge, Buttons)
    ├── Screens/ (LeadFeed, LeadDetail, Setup, Keywords, etc.)
    └── ViewModels/ (LeadFeedViewModel, ProductSetupViewModel, etc.)
```
