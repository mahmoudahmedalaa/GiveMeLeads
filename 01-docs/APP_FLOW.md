# Application Flow & Navigation

> Every screen, every transition, every user decision mapped out. AI builds exactly what's documented here — no guessing.

## 1. Navigation Structure

### App Architecture
<!-- Choose one: Tab-based / Stack / Drawer / Hybrid -->

```
App Root
├── [Tab/Section 1] — [Purpose]
│   ├── Screen 1.1 — [Name]
│   └── Screen 1.2 — [Name]
├── [Tab/Section 2] — [Purpose]
│   ├── Screen 2.1 — [Name]
│   └── Screen 2.2 — [Name]
├── [Modal Screens]
│   └── Screen M.1 — [Name]
└── [Auth Screens]
    ├── Login
    ├── Register
    └── Forgot Password
```

---

## 2. Screen Specifications

### Screen: [Name]

**Route**: `/path/to/screen`  
**Access**: Public / Authenticated / Premium  
**Purpose**: [One sentence]

#### Layout
```
┌─────────────────────────────┐
│         Header / Nav        │
├─────────────────────────────┤
│                             │
│       [Main Content]        │
│                             │
├─────────────────────────────┤
│       [Actions / CTA]       │
└─────────────────────────────┘
```

#### Elements
| Element | Type | Behavior |
|:--------|:-----|:---------|
| | Button / Input / List / etc. | What happens on interaction |

#### States
- **Loading**: [What shows while data loads]
- **Empty**: [What shows with no data]
- **Error**: [What shows on failure]
- **Success**: [Confirmation behavior]

#### Navigation
- **Entry**: How users arrive at this screen
- **Exit**: Where users go from here
- **Back**: Behavior of back button/gesture

---

## 3. User Flows

### Flow 1: First-Time User Experience

```
App Launch
    │
    ├─ First launch? ─── YES ──→ Welcome Screen
    │                                  │
    │                            Onboarding (3-5 steps)
    │                                  │
    │                            Auth Screen
    │                             ├── Sign Up
    │                             ├── Social Login
    │                             └── Skip (if allowed)
    │                                  │
    │                             Home Screen
    │
    └─ Returning user ──→ Home Screen
```

### Flow 2: Core Feature Flow
```
[Map your primary use case here]
```

### Flow 3: Authentication Flow
```
Login Screen
    │
    ├── Email/Password
    │   ├── Valid ──→ Home
    │   ├── Wrong password ──→ Error message
    │   └── Unverified ──→ "Check email" message
    │
    ├── Social Login (Google/Apple)
    │   ├── Success ──→ Home
    │   └── Cancelled ──→ Stay on Login
    │
    └── Forgot Password
        ├── Send reset email ──→ Confirmation
        └── Error ──→ "Email not found"
```

### Flow 4: Settings & Account
```
Settings Screen
    ├── Profile / Account
    │   ├── Edit Profile
    │   ├── Change Password
    │   └── Delete Account (with confirmation!)
    ├── Preferences
    │   ├── Theme (Light/Dark)
    │   ├── Notifications
    │   └── Language
    └── Sign Out (with confirmation)
```

---

## 4. State Transitions

### Authentication States
```
ANONYMOUS → REGISTERED → VERIFIED → AUTHENTICATED
                                         ↕
                                    SIGNED_OUT
```

### Data States (per entity)
```
LOADING → LOADED → STALE → REFRESHING → LOADED
              ↓
           EMPTY
              ↓
         ERROR → RETRY → LOADING
```

---

## 5. Error Handling UX

| Error Type | User-Facing Message | Action |
|:-----------|:---------------------|:-------|
| Network offline | "No internet connection" | Retry button |
| Auth expired | "Session expired" | Redirect to login |
| Server error | "Something went wrong" | Retry button |
| Not found | "Content not available" | Back button |
| Permission denied | "Upgrade to access" | Upgrade CTA |

---

## 6. Deep Linking (if applicable)

| Link Pattern | Target Screen | Parameters |
|:-------------|:--------------|:-----------|
| `app://item/:id` | Item Detail | `id` |
| `app://settings` | Settings | — |

---

## AI Generation Prompt

```
Create a comprehensive Application Flow document for [YOUR APP].

App Type: [Tab-based mobile / Single-page web / Dashboard]
Main Features: [LIST 3-5 CORE FEATURES]
Auth Required: [Yes/No/Optional]
Platform: [iOS / Android / Web]

Generate documentation with:

1. NAVIGATION STRUCTURE: ASCII tree showing all screens and hierarchy
2. SCREEN SPECIFICATIONS: For each screen, provide:
   - Route path
   - Access level (Public/Auth/Premium)
   - ASCII layout wireframe
   - Interactive elements table
   - States (loading, empty, error, success)
   - Navigation entry/exit points
3. USER FLOWS: ASCII flowcharts for:
   - First-time user experience (onboarding → auth → home)
   - Core feature primary flow
   - Authentication (login, register, forgot password)
   - Settings and account management
4. STATE TRANSITIONS: Diagrams for auth states and data loading states
5. ERROR HANDLING: Table mapping error types to user messages and actions

Use ASCII art for wireframes and flowcharts. Be specific about what each element does.
```
