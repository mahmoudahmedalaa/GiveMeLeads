# GiveMeLeads

AI-powered lead generation from Reddit. Native iOS app built with Swift & SwiftUI.

## What It Does

GiveMeLeads monitors Reddit 24/7 for high-intent leads — people actively looking for products or services like yours. Every lead gets an AI intent score (0-100), and you get smart reply suggestions to engage at the perfect moment.

## Features (MVP)

- **Keyword Tracking** — Set up keyword profiles to monitor specific subreddits
- **Lead Discovery Feed** — Swipeable card feed sorted by AI intent score
- **AI Lead Scoring** — Automatic scoring based on intent, urgency, and fit
- **Smart Replies** — AI-generated reply suggestions in 3 tones (professional, casual, helpful)
- **Push Notifications** — Real-time alerts for high-score leads
- **Subscription** — 7-day free trial, $19/month

## Tech Stack

| Layer | Technology |
|:------|:-----------|
| **Frontend** | Swift 5.9+, SwiftUI, iOS 17+ |
| **Architecture** | MVVM + Clean Architecture |
| **Backend** | Supabase (PostgreSQL, Auth, Edge Functions) |
| **AI** | Apple NaturalLanguage framework + heuristic scoring |
| **Payments** | StoreKit 2 + RevenueCat |
| **Data Source** | Reddit API (OAuth2) |

## Project Structure

```
GiveMeLeads/
├── GiveMeLeads/          ← iOS app source code
│   ├── App/              ← Entry point, router, tabs
│   ├── Core/             ← Config, constants, extensions
│   ├── Domain/           ← Entities, repositories, use cases
│   ├── Data/             ← API clients, local storage
│   ├── Presentation/     ← Screens, components, theme
│   └── Infrastructure/   ← Supabase, notifications, purchases
├── 00-research/          ← Market research & competitor analysis
├── 01-docs/              ← PRD, tech stack, app flow, design system
└── 02-agent/             ← AI agent rules & skills
```

## Getting Started

1. Open `GiveMeLeads.xcodeproj` in Xcode 16+
2. Set your team & bundle identifier
3. Add API keys to `Secrets.xcconfig` (see `AppConfig.swift`)
4. Build and run on iOS 17+ Simulator or device

## License

Private — All rights reserved.
