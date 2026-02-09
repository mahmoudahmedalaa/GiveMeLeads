# Technology Stack

> Every technology decision locked down with exact versions. No "latest" — pin everything.

## 1. Stack Overview

| Dimension | Decision | Justification |
|:----------|:---------|:--------------|
| **Architecture** | MVVM + Clean Architecture | Testable, scalable, standard for Swift/SwiftUI |
| **Platform** | iOS 17+ (SwiftUI) | Modern APIs, SwiftData, Observation framework |
| **Deployment** | App Store (via Xcode Archive) | Standard iOS distribution |
| **Scale Target** | MVP → 1K users | Supabase free tier covers this |

---

## 2. Frontend Stack (iOS Client)

| Technology | Version | Purpose | Docs | Alternative Considered |
|:-----------|:--------|:--------|:-----|:-----------------------|
| **Framework** | SwiftUI | Declarative UI framework | [apple.com](https://developer.apple.com/swiftui/) | UIKit (more boilerplate) |
| **Language** | Swift 5.9+ | Type-safe, modern | [swift.org](https://www.swift.org/) | — |
| **State Mgmt** | @Observable (Observation) | MVVM reactive state | [apple.com](https://developer.apple.com/documentation/observation) | Combine (more verbose) |
| **Navigation** | NavigationStack | SwiftUI navigation | Built-in | Coordinator pattern (overkill for MVP) |
| **Local Storage** | SwiftData | Persistent local cache | [apple.com](https://developer.apple.com/swiftdata/) | Core Data (older API) |
| **Networking** | URLSession + async/await | HTTP requests | Built-in | Alamofire (unnecessary dependency) |
| **Animations** | SwiftUI Animations | Micro-interactions, transitions | Built-in | — |
| **Charts** | Swift Charts | Analytics visualizations | [apple.com](https://developer.apple.com/documentation/charts) | — |
| **Push Notifications** | APNs via Supabase | Real-time lead alerts | [apple.com](https://developer.apple.com/notifications/) | Firebase FCM |

---

## 3. Backend Stack

| Technology | Version | Purpose | Docs | Alternative Considered |
|:-----------|:--------|:--------|:-----|:-----------------------|
| **BaaS** | Supabase | Database, Auth, Edge Functions | [supabase.com](https://supabase.com/docs) | Firebase (less SQL-friendly) |
| **Database** | PostgreSQL 15 (via Supabase) | Structured lead & user data | Via Supabase | — |
| **Auth** | Supabase Auth | Email/password + Sign in with Apple | [auth docs](https://supabase.com/docs/guides/auth) | Firebase Auth |
| **Edge Functions** | Supabase Edge Functions (Deno) | Reddit API proxy, AI scoring | [functions docs](https://supabase.com/docs/guides/functions) | Vercel serverless |
| **Realtime** | Supabase Realtime | Live lead feed updates | [realtime docs](https://supabase.com/docs/guides/realtime) | WebSockets |
| **File Storage** | Not needed for MVP | — | — | — |
| **Payments** | StoreKit 2 + RevenueCat | Apple IAP subscriptions | [revenuecat.com](https://www.revenuecat.com/docs) | Raw StoreKit (harder) |
| **Analytics** | TelemetryDeck | Privacy-first analytics | [telemetrydeck.com](https://telemetrydeck.com/docs/) | Mixpanel (privacy concerns) |

---

## 4. AI Stack

| Technology | Version | Purpose | Docs | Alternative Considered |
|:-----------|:--------|:--------|:-----|:-----------------------|
| **Lead Scoring** | On-device NL model (NaturalLanguage framework) | Intent classification, free, private | [apple.com](https://developer.apple.com/documentation/naturallanguage) | OpenAI API ($) |
| **Reply Generation** | Supabase Edge Function → free model API | Generate reply suggestions | Via Hugging Face or Ollama | OpenAI API ($) |
| **Fallback** | Rule-based scoring | If AI unavailable, use keyword heuristics | Custom | — |

### AI Strategy (Free Tier)
- **Primary**: Apple's NaturalLanguage framework for on-device sentiment/intent analysis (zero cost)
- **Secondary**: Free tier of Hugging Face Inference API for reply generation (~1,000 free requests/month)
- **Fallback**: Rule-based keyword matching + intent heuristics (always available, zero cost)

---

## 5. External APIs

| API | Version | Purpose | Rate Limits | Cost |
|:----|:--------|:--------|:------------|:-----|
| **Reddit API** | OAuth2 | Fetch matching posts | 60 req/min per user | Free |
| **Hugging Face Inference** | v1 | AI reply generation | 1,000 req/mo (free) | Free |

---

## 6. Development Tools

| Tool | Version | Purpose |
|:-----|:--------|:--------|
| **IDE** | Xcode 16+ | Development |
| **Package Manager** | Swift Package Manager | Dependencies |
| **Linter** | SwiftLint 0.54+ | Code quality |
| **Testing** | XCTest | Unit + UI tests |
| **Formatter** | swift-format | Consistent code style |
| **Version Control** | Git + GitHub | Source control |

---

## 7. Swift Package Dependencies

```swift
// Package.swift / Xcode SPM
dependencies: [
    // Supabase
    .package(url: "https://github.com/supabase-community/supabase-swift", from: "2.0.0"),
    
    // RevenueCat
    .package(url: "https://github.com/RevenueCat/purchases-ios-spm", from: "5.0.0"),
    
    // SwiftLint (build tool plugin)
    .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.54.0"),
    
    // Lottie (onboarding animations)
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.4.0"),
    
    // TelemetryDeck
    .package(url: "https://github.com/TelemetryDeck/SwiftClient", from: "2.0.0"),
]
```

---

## 8. Environment Variables

```bash
# Supabase
SUPABASE_URL="https://[project-ref].supabase.co"
SUPABASE_ANON_KEY="eyJ..."

# Reddit API
REDDIT_CLIENT_ID="your-reddit-app-id"
REDDIT_CLIENT_SECRET="your-reddit-secret"

# RevenueCat
REVENUECAT_API_KEY="appl_..."

# TelemetryDeck
TELEMETRYDECK_APP_ID="your-app-id"

# Hugging Face (for reply generation)
HUGGINGFACE_API_KEY="hf_..."
```

> ⚠️ Never commit secrets. Use Xcode configuration files (.xcconfig) with .gitignore.

---

## 9. Security Considerations

| Area | Approach |
|:-----|:---------|
| **Authentication** | Supabase Auth (JWT, 1hr access / 7d refresh) |
| **Secrets** | .xcconfig files, never in source code |
| **API Security** | HTTPS only, Supabase RLS (Row Level Security) |
| **Rate Limiting** | Reddit API: respect 60/min; Supabase: default limits |
| **Data Protection** | Supabase encryption at rest; iOS Keychain for tokens |
| **App Transport Security** | HTTPS enforced by iOS |
