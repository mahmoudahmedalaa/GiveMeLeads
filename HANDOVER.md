# GiveMeLeads — AI Assistant Handover Document
**Date:** February 17, 2026  
**Project:** Native iOS App (SwiftUI, Supabase backend)  
**Location:** `/Users/mahmoudalaaeldin/Documents/Projects/VibeCoding/Projects/GiveMeLeads/GiveMeLeads/`  
**Xcode Project:** `GiveMeLeads.xcodeproj`  
**Build Status:** ✅ Compiles with zero warnings, zero errors (exit code 0)

---

## 1. What This App Does

GiveMeLeads is a native iOS app that helps users discover potential customers (leads) on Reddit. Users create **Tracking Profiles** with keywords and target subreddits. The app scans Reddit (client-side), scores posts/comments by relevance using AI, and presents them as actionable leads with AI-generated reply suggestions.

### Core User Flow
1. **Sign up** → Email OTP or Sign in with Apple
2. **Onboarding** → Feature overview slides
3. **Product Setup** → Create first tracking profile (product name, keywords, subreddits)
4. **Lead Feed** → View discovered leads, sorted by AI-scored relevance
5. **Scan** → Manually trigger Reddit scans for a specific profile
6. **Lead Actions** → Save, dismiss, reply with AI-generated responses, view on Reddit
7. **Profiles tab** → Manage multiple tracking profiles & keywords
8. **Saved tab** → View bookmarked leads
9. **Settings** → Account, appearance toggle, product description

---

## 2. Architecture Overview

```
GiveMeLeads/
├── App/                          # App entry point & navigation
│   ├── GiveMeLeadsApp.swift      # @main, applies colorScheme
│   ├── RootView.swift            # Auth state router (loading/unauth/onboarding/setup/auth)
│   ├── AppRouter.swift           # Observable nav state (AuthState enum + tab selection)
│   └── MainTabView.swift         # 4-tab layout: Leads, Profiles, Saved, Settings
│
├── Domain/
│   └── Entities/
│       ├── Lead.swift            # Lead model (id, profileId, score, scoreBreakdown, etc.)
│       ├── TrackingProfile.swift  # TrackingProfile + Keyword models
│       └── AIReply.swift         # AI reply suggestion model
│
├── Data/
│   ├── Repositories/
│   │   ├── AuthRepository.swift       # OTP, Apple Sign In, session, delete account
│   │   ├── LeadRepository.swift       # CRUD leads (by profile or all)
│   │   ├── KeywordRepository.swift    # Profiles & keywords CRUD
│   │   └── AIReplyRepository.swift    # AI reply generation
│   └── Services/
│       ├── RedditSearchService.swift  # CLIENT-SIDE Reddit scanning (~31KB, the big one)
│       ├── RedditScanService.swift     # Legacy edge function scanner (deprecated)
│       ├── ProductAnalyzer.swift       # AI scoring via Supabase Edge Function
│       ├── SubredditSearchService.swift # Subreddit discovery
│       └── GatingService.swift         # Free tier limits & scan cooldowns
│
├── Infrastructure/
│   ├── Supabase/                 # SupabaseManager singleton (client init)
│   ├── Purchases/                # RevenueCat / StoreKit integration
│   └── Notifications/           # Push notification config & custom notification names
│
├── Presentation/
│   ├── Theme/
│   │   ├── AppColors.swift       # Design system colors & gradients
│   │   ├── AppTypography.swift   # Font definitions
│   │   ├── AppSpacing.swift      # Spacing constants
│   │   └── AppearanceManager.swift # System/Light/Dark toggle (Observable singleton)
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift          # Auth flow (OTP send/verify, Apple, session)
│   │   ├── LeadFeedViewModel.swift      # Core VM (~600 lines): scanning, lead fetch, profiles
│   │   ├── KeywordViewModel.swift       # Profile & keyword management
│   │   ├── ProductSetupViewModel.swift  # First-time setup + onboarding scan
│   │   └── Entitlements.swift           # Subscription state management
│   ├── Screens/
│   │   ├── Welcome/
│   │   │   ├── WelcomeScreen.swift      # Sign in (Apple + Email OTP entry)
│   │   │   └── OTPVerificationScreen.swift # 6-digit code entry
│   │   ├── Onboarding/                  # Feature overview slides
│   │   ├── Setup/                       # First profile creation wizard
│   │   ├── LeadFeed/
│   │   │   └── LeadFeedScreen.swift     # Main feed with profile selector pills
│   │   ├── LeadDetail/
│   │   │   └── LeadDetailScreen.swift   # Full lead view + AI reply
│   │   ├── Keywords/                    # Profile management
│   │   ├── Saved/
│   │   │   └── SavedLeadsScreen.swift   # Bookmarked leads
│   │   ├── Settings/
│   │   │   └── SettingsScreen.swift     # Account, appearance, product desc
│   │   └── Paywall/                     # Subscription paywall
│   └── Components/
│       ├── LeadCard/
│       │   ├── LeadCardView.swift       # Lead card with optional profileName badge
│       │   └── ScoreBadge/              # Score indicator
│       ├── Common/                      # PrimaryButton, shared UI
│       ├── Chip/                        # Tag chips
│       └── UpgradeBanner.swift          # Free tier upsell
```

---

## 3. Backend (Supabase)

### Database Tables
| Table | Purpose |
|-------|---------|
| `users` | User profiles (synced from auth) |
| `tracking_profiles` | Product profiles with name, subreddits, is_active |
| `keywords` | Keywords per profile (keyword text, is_exact_match) |
| `leads` | Discovered leads (linked to profile_id, scored) |

### Key Relationships
- `users` → has many `tracking_profiles`
- `tracking_profiles` → has many `keywords`
- `tracking_profiles` → has many `leads` (via `profile_id`)
- `leads.profile_id` is nullable (some legacy leads may have NULL)

### Edge Functions
- Lead scoring/analysis via `ProductAnalyzer.swift` calls Supabase Edge Function
- Reddit scan was originally server-side but Reddit blocks Supabase IPs → **moved to client-side** (`RedditSearchService.swift`)

### Auth
- Supabase Auth with **Email OTP** and **Sign in with Apple**
- Magic link deep link handler still exists for backward compat

---

## 4. Recent Changes Made (This Session)

### ✅ Fixed: OTP Code Validation Bug
- **Problem:** User enters 6-digit code → gets "please enter 6 digit code" error
- **Root Cause:** `TextField` allowed non-digit characters (spaces/dashes from autofill/paste). `verifyOTP()` checked count after trimming whitespace, but didn't filter non-digits
- **Fix:** Added digit-only filtering in `OTPVerificationScreen.onChange` + `verifyOTP()` now filters to digits before count check + added `!isLoading` guard to prevent double-submit
- **Files:** `AuthViewModel.swift`, `OTPVerificationScreen.swift`

### ✅ Fixed: Lead Wiping Bug
- **Problem:** Adding a second profile made existing leads disappear
- **Root Cause:** `.profileCreated` notification handler auto-switched to the new (empty) profile
- **Fix:** Only auto-select on first profile; subsequent profiles just refresh the list
- **File:** `LeadFeedViewModel.swift` (notification handler in init)

### ✅ Added: Multi-Profile Filtering ("All" mode)
- Profile selector pills now show "All" option when 2+ profiles exist
- "All" mode shows leads from all profiles with profile name badges
- Scan button disabled in "All" mode (must select specific profile to scan)
- **Files:** `LeadFeedViewModel.swift`, `LeadFeedScreen.swift`, `LeadCardView.swift`

### ✅ Added: Profile Name Badges on Saved Leads
- Saved leads now show which profile they belong to
- **File:** `SavedLeadsScreen.swift`

### ✅ Added: Appearance Toggle (System / Light / Dark)
- New `AppearanceManager.swift` singleton using `@AppStorage`
- Settings screen has segmented picker
- Applied globally in `GiveMeLeadsApp.swift`

### ✅ Cleaned: Compiler Warnings
- Removed unused `failureCount` variable in `LeadFeedViewModel.swift`
- Fixed unused `try?` result in `ProductSetupViewModel.swift`

---

## 5. Known Issues & Things That Need Attention

> [!CAUTION]
> These are issues the user has flagged or that exist in the codebase. The next AI assistant should audit and address these.

### 🔴 Critical — Must Test First
1. **OTP Flow End-to-End:** The OTP fix has been code-verified but needs device testing. Verify autofill from iOS keyboard works, pasting codes works, and the auto-verify triggers on 6 digits.
2. **Post-Auth Navigation:** Verify the full flow: OTP verify → `handleAuthStateChange(isAuthenticated: true)` → `checkNeedsSetup()` → correct screen (onboarding/setup/main). The user may be hitting a navigation issue after OTP.
3. **Session Persistence:** Verify `checkSession()` works on cold launch — if session exists in Supabase, user should skip login entirely.

### 🟡 Medium Priority
4. **`RootView.swift` creates new `AuthViewModel` on every `.task`:** This means each app launch creates a fresh AuthViewModel that's separate from the one used in `WelcomeScreen`. This is architecturally wrong — session check and login should share the same instance.
5. **Lead scanning cooldown behavior:** `GatingService.swift` manages free tier limits. Need to verify these are working correctly per-profile.
6. **Reddit API rate limiting:** `RedditSearchService.swift` is 31KB. The client-side scanning can hit Reddit rate limits. Needs proper error handling UX.
7. **"Clear all" button in All profiles mode:** Currently visible but should probably be hidden or prompt which profile to clear.
8. **Paywall integration:** Check if `Entitlements.swift` and the paywall flow are properly gating features.
9. **Profile deletion cascade:** When a profile is deleted, verify leads are cleaned up properly.

### 🟢 Nice to Have
10. **Onboarding flow:** Review the onboarding slides for completeness and visual quality.
11. **Empty states:** Various screens may need better empty state messaging.
12. **Error handling consistency:** Some ViewModels use `AppError.from()`, others use raw error messages.

---

## 6. How to Build & Run

```bash
# Navigate to project
cd /Users/mahmoudalaaeldin/Documents/Projects/VibeCoding/Projects/GiveMeLeads/GiveMeLeads

# Clean build (verify compilation)
xcodebuild clean build -scheme GiveMeLeads -destination 'generic/platform=iOS' -quiet

# For archive (App Store submission)
# Open Xcode → Product → Archive
```

### Requirements
- Xcode (latest)
- iOS 17+ target
- Supabase account configured (credentials in `SupabaseManager.swift`)
- RevenueCat configured (for subscriptions)

---

## 7. Key Design Patterns

| Pattern | Usage |
|---------|-------|
| `@Observable` + `@Environment` | ViewModels and AppRouter are Observable objects passed via environment |
| Repository Pattern | `AuthRepository`, `LeadRepository`, `KeywordRepository`, `AIReplyRepository` — all have protocols |
| Singleton services | `SupabaseManager.shared`, `AppearanceManager.shared` |
| Notification Center | `.profileCreated` notification for cross-VM communication |
| `@AppStorage` | Persists `hasSeenOnboarding`, `appearanceMode` |
| Client-side scanning | Reddit scan happens on-device via `RedditSearchService` (not server) |

---

## 8. Supabase Project Info

The Supabase configuration is in `Infrastructure/Supabase/SupabaseManager.swift`. Check that file for the project URL and anon key. The database schema uses Row Level Security (RLS) — all queries are scoped to the authenticated user automatically.

---

## 9. File Quick Reference

| If you need to... | Look at... |
|--------------------|------------|
| Fix auth/login issues | `AuthViewModel.swift`, `AuthRepository.swift`, `OTPVerificationScreen.swift`, `WelcomeScreen.swift` |
| Fix navigation/routing | `AppRouter.swift`, `RootView.swift` |
| Fix lead feed/scanning | `LeadFeedViewModel.swift` (600 lines — the biggest file), `RedditSearchService.swift` |
| Fix profile management | `KeywordViewModel.swift`, `KeywordRepository.swift` |
| Fix saved leads | `SavedLeadsScreen.swift`, `LeadRepository.swift` |
| Fix subscriptions/paywall | `Entitlements.swift`, `PaywallScreen.swift`, `GatingService.swift` |
| Fix theme/colors | `AppColors.swift`, `AppearanceManager.swift` |
| Fix first-time setup | `ProductSetupViewModel.swift`, `ProductSetupScreen.swift` |
| Understand the data model | `Lead.swift`, `TrackingProfile.swift` |
| Check Supabase config | `Infrastructure/Supabase/SupabaseManager.swift` |

---

## 10. Immediate Next Steps for New AI

1. **Build the app and run on device** — verify login with OTP works end to end
2. **Walk through every screen** — check for visual bugs, broken navigation, missing data
3. **Test the scan flow** — select a profile → tap scan → verify leads appear with scores
4. **Test multi-profile** — create 2 profiles, switch between them, verify "All" mode
5. **Test saved leads** — save a lead, check it appears in Saved tab with profile badge
6. **Verify theme toggle** — switch between System/Light/Dark in Settings
7. **Check paywall** — verify free tier limits work, upgrade flow works
8. **Address any bugs found** during the above walkthrough
