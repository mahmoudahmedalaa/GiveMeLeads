# Application Flow & Navigation

> Every screen, every transition, every user decision mapped out. AI builds exactly what's documented here — no guessing.

## 1. Navigation Structure

### App Architecture: Tab-based + Modal

```
App Root
├── 🔐 Auth Stack (unauthenticated)
│   ├── WelcomeScreen
│   ├── OnboardingScreen (3 slides)
│   ├── LoginScreen
│   └── SignUpScreen
│
├── 🏠 Main Tab Bar (authenticated)
│   ├── Tab 1: Leads — Lead Discovery Feed
│   │   ├── LeadFeedScreen
│   │   └── LeadDetailScreen (push)
│   │
│   ├── Tab 2: Keywords — Keyword Management
│   │   ├── KeywordListScreen
│   │   ├── AddKeywordScreen (sheet)
│   │   └── EditKeywordScreen (sheet)
│   │
│   ├── Tab 3: Saved — Saved Leads
│   │   ├── SavedLeadsScreen
│   │   └── LeadDetailScreen (push)
│   │
│   └── Tab 4: Settings — Account & Preferences
│       ├── SettingsScreen
│       ├── ProfileScreen (push)
│       ├── NotificationSettingsScreen (push)
│       ├── SubscriptionScreen (push)
│       └── AboutScreen (push)
│
└── 🚫 Paywall (modal)
    └── PaywallScreen (fullScreenCover)
```

---

## 2. Screen Specifications

### Screen: Welcome
**Route**: First launch only  
**Access**: Public  
**Purpose**: Brand impression and onboarding entry

#### Layout
```
┌─────────────────────────────┐
│                             │
│      [App Logo + Name]      │
│      "GiveMeLeads"         │
│                             │
│    [Animated illustration]  │
│    "Find leads that want    │
│     what you offer"         │
│                             │
│    ┌─────────────────────┐  │
│    │   Get Started →      │  │
│    └─────────────────────┘  │
│                             │
│    Already have account?    │
│          Sign In            │
└─────────────────────────────┘
```

#### Navigation
- **Entry**: App first launch
- **Exit**: "Get Started" → Onboarding, "Sign In" → LoginScreen

---

### Screen: Onboarding (3 slides)
**Route**: After Welcome  
**Access**: Public  
**Purpose**: Explain value proposition

#### Slides
```
Slide 1: "🎯 Discover"
"AI monitors Reddit 24/7 for people
 looking for what you offer"
[Illustration: radar scanning]

Slide 2: "📊 Score"
"Every lead gets an AI intent score
 so you focus on the best ones"
[Illustration: lead cards with scores]

Slide 3: "💬 Engage"
"Get smart reply suggestions and
 respond at the perfect moment"
[Illustration: chat bubbles]
```

#### Elements
| Element | Type | Behavior |
|:--------|:-----|:---------|
| Page indicator | Dots | Shows current slide |
| Next button | Button | Advances to next slide |
| Skip button | Text button | Jumps to Sign Up |
| Continue button | Primary button | On slide 3, goes to Sign Up |

---

### Screen: Lead Feed
**Route**: Tab 1 (default)  
**Access**: Authenticated  
**Purpose**: Browse and triage Reddit leads

#### Layout
```
┌─────────────────────────────┐
│  GiveMeLeads     🔍 Filter  │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 🟢 92  r/SaaS  · 2h ago │ │
│ │                         │ │
│ │ "Looking for a project  │ │
│ │  management tool that..." │ │
│ │                         │ │
│ │  u/techguy42  ↑ 47  💬12│ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🟡 67  r/startup  · 5h  │ │
│ │                         │ │
│ │ "Can anyone recommend   │ │
│ │  a CRM for small..."    │ │
│ │                         │ │
│ │  u/founder99  ↑ 23  💬8 │ │
│ └─────────────────────────┘ │
│                             │
│         [More cards...]     │
├─────────────────────────────┤
│  🏠 Leads  🔑 Keywords     │
│  📌 Saved  ⚙️ Settings     │
└─────────────────────────────┘
```

#### Elements
| Element | Type | Behavior |
|:--------|:-----|:---------|
| Lead card | Swipeable card | Tap → detail; swipe R → save; swipe L → dismiss |
| Score badge | Colored badge | Green ≥80, Yellow 50-79, Gray <50 |
| Filter button | Icon button | Opens filter sheet |
| Pull-to-refresh | Gesture | Fetches latest leads |

#### States
- **Loading**: Skeleton cards (3-4 placeholders)
- **Empty**: Illustration + "No leads yet. Set up keywords to start!" with CTA
- **Error**: "Couldn't load leads. Pull to retry." + retry button
- **Success**: Scrollable list of lead cards

---

### Screen: Lead Detail
**Route**: Push from LeadFeedScreen or SavedLeadsScreen  
**Access**: Authenticated  
**Purpose**: Full lead context + AI engagement

#### Layout
```
┌─────────────────────────────┐
│  ← Back         ⋯ Actions   │
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │ 🟢 Score: 92/100      │  │
│  │ Intent · Urgency · Fit│  │
│  └───────────────────────┘  │
│                             │
│  r/SaaS · 2 hours ago      │
│  u/techguy42 · ↑47 · 💬12  │
│                             │
│  "Looking for a project     │
│   management tool that      │
│   handles dependencies and  │
│   has a good mobile app.    │
│   Currently using Asana but │
│   it's too expensive..."    │
│                             │
│  ─────────────────────────  │
│                             │
│  💡 AI Reply Suggestions    │
│                             │
│  ┌───────────────────────┐  │
│  │ 🎯 Professional         │  │
│  │ "You might want to     │  │
│  │  check out [Product]..." │  │
│  │          [Copy] 📋     │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ 💬 Casual              │  │
│  │ "Hey! I use [Product]  │  │
│  │  for exactly this..."  │  │
│  │          [Copy] 📋     │  │
│  └───────────────────────┘  │
│                             │
├─────────────────────────────┤
│ [📌 Save] [🔗 Open Reddit] │
│ [✅ Mark Contacted] [❌ Dismiss]│
└─────────────────────────────┘
```

#### States
- **Loading**: Skeleton layout
- **Error**: "Post no longer available" message
- **AI loading**: Shimmer effect on reply suggestion cards

---

### Screen: Keyword Management
**Route**: Tab 2  
**Access**: Authenticated  
**Purpose**: Configure tracking keywords and subreddits

#### Layout
```
┌─────────────────────────────┐
│  Keywords           ＋ Add   │
├─────────────────────────────┤
│                             │
│  Profile: "My SaaS" 🟢 ON  │
│  ┌───────────────────────┐  │
│  │ project management    ✕│  │
│  │ task app recommend    ✕│  │
│  │ Asana alternative     ✕│  │
│  └───────────────────────┘  │
│  Subreddits: r/SaaS,       │
│  r/productivity, r/startup  │
│                             │
│  ─────────────────────────  │
│                             │
│  Profile: "Freelance" 🔴 OFF │
│  ┌───────────────────────┐  │
│  │ looking for developer ✕│  │
│  │ need a freelancer     ✕│  │
│  └───────────────────────┘  │
│  Subreddits: r/forhire,    │
│  r/freelance                │
│                             │
├─────────────────────────────┤
│  3/10 keywords · 2/3 profiles│
└─────────────────────────────┘
```

---

### Screen: Settings
**Route**: Tab 4  
**Access**: Authenticated  
**Purpose**: Account management and preferences

#### Layout
```
┌─────────────────────────────┐
│  Settings                   │
├─────────────────────────────┤
│                             │
│  ACCOUNT                    │
│  ┌───────────────────────┐  │
│  │ 👤 Profile          → │  │
│  │ 💳 Subscription     → │  │
│  └───────────────────────┘  │
│                             │
│  PREFERENCES                │
│  ┌───────────────────────┐  │
│  │ 🔔 Notifications    → │  │
│  │ 🎯 Min. Score: 70  ─○ │  │
│  │ 🌙 Dark Mode   [ON]  │  │
│  └───────────────────────┘  │
│                             │
│  ABOUT                      │
│  ┌───────────────────────┐  │
│  │ ℹ️  About GiveMeLeads → │  │
│  │ 📜 Privacy Policy    → │  │
│  │ 📧 Contact Support   → │  │
│  │ ⭐ Rate on App Store → │  │
│  └───────────────────────┘  │
│                             │
│  [Sign Out]                 │
│                             │
│  Trial: 5 days remaining    │
└─────────────────────────────┘
```

---

## 3. User Flows

### Flow 1: First-Time User Experience

```
App Launch
    │
    ├─ First launch? ─── YES ──→ Welcome Screen
    │                                  │
    │                            Onboarding (3 slides)
    │                                  │
    │                            Sign Up Screen
    │                             ├── Sign in with Apple
    │                             └── Email + Password
    │                                  │
    │                            Keyword Setup (guided)
    │                             ├── "What do you offer?"
    │                             ├── Add 2-5 keywords
    │                             └── Select subreddits
    │                                  │
    │                            Lead Feed (first results)
    │                                  │
    │                            ✅ Setup Complete
    │
    └─ Returning user ──→ Lead Feed (Tab 1)
```

### Flow 2: Core Feature Flow (Lead Discovery → Engagement)
```
Lead Feed
    │
    ├── See scored lead card
    │   ├── Swipe RIGHT ──→ Save to "Saved" tab
    │   ├── Swipe LEFT  ──→ Dismiss (hidden from feed)
    │   └── TAP         ──→ Lead Detail Screen
    │                           │
    │                     ├── Read full post
    │                     ├── View AI reply suggestions
    │                     ├── Copy reply → Open Reddit
    │                     ├── Mark as Contacted
    │                     └── Back to Feed
    │
    └── Pull to refresh ──→ Fetch new leads
```

### Flow 3: Authentication Flow
```
Login Screen
    │
    ├── Sign in with Apple
    │   ├── Success ──→ Lead Feed
    │   └── Cancelled ──→ Stay on Login
    │
    ├── Email/Password
    │   ├── Valid ──→ Lead Feed
    │   ├── Wrong password ──→ Shake + error message
    │   └── No account ──→ "Sign up instead?" link
    │
    └── Forgot Password
        ├── Send reset email ──→ "Check your inbox" confirmation
        └── Error ──→ "Email not found"
```

### Flow 4: Subscription Flow
```
Trial Expires
    │
    ├── Open app ──→ Paywall (fullScreenCover)
    │                  │
    │                  ├── Subscribe ($19/mo) ──→ Apple IAP
    │                  │   ├── Success ──→ Lead Feed (full access)
    │                  │   └── Failed  ──→ Error + Retry
    │                  │
    │                  └── Not now ──→ Limited mode
    │                      (can view feed, can't interact)
    │
    └── Settings → Subscription → Manage
        ├── View plan details
        ├── Restore purchases
        └── Open Apple subscription management
```

---

## 4. State Transitions

### Authentication States
```
ANONYMOUS → SIGNING_UP → TRIAL_ACTIVE → TRIAL_EXPIRED → SUBSCRIBED
                                              ↓
                                         LIMITED_MODE
                                              ↕
                                         SUBSCRIBED
```

### Lead States
```
DISCOVERED → NEW → SAVED → CONTACTED → CONVERTED
                     ↘
                   DISMISSED
```

### Data States (per screen)
```
IDLE → LOADING → LOADED → STALE → REFRESHING → LOADED
                    ↓
                 EMPTY
                    ↓
              ERROR → RETRY → LOADING
```

---

## 5. Error Handling UX

| Error Type | User-Facing Message | Action |
|:-----------|:---------------------|:-------|
| Network offline | "No internet connection" | Retry button + show cached data |
| Auth expired | "Session expired" | Auto-refresh token, fallback to login |
| Reddit API error | "Couldn't fetch latest leads" | Retry button + show cached |
| AI scoring failed | "Score pending" | Show lead without score |
| Post deleted | "This post is no longer available" | Back button |
| Trial expired | "Your free trial has ended" | Upgrade CTA |
| Purchase failed | "Payment couldn't be processed" | Retry / contact support |

---

## 6. Deep Linking

| Link Pattern | Target Screen | Parameters |
|:-------------|:--------------|:-----------|
| `givemeleads://lead/:id` | Lead Detail | `leadId` |
| `givemeleads://keywords` | Keyword Management | — |
| `givemeleads://subscribe` | Paywall | — |
