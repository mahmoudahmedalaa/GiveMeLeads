---
description: Core development principles that must be followed at all times during GiveMeLeads development
---

# Development Principles

These are mandatory principles established by the project owner. Follow them at ALL times.

## 1. Free Only — No Paid Services for MVP
- Use **free tiers only**: Supabase free, HuggingFace free, Reddit API free
- No paid AI APIs (no OpenAI, no Anthropic API)
- Use on-device Apple NaturalLanguage framework for scoring (zero cost)
- RevenueCat free tier for subscription management
- If a paid service is the only option, **ask the user first**

## 2. Test Extensively — No Broken Code
- **Test every feature** before committing
- Write unit tests alongside implementation (not deferred)
- Verify builds compile before every git push
- Run the app in Simulator to confirm UI works
- Never commit code that doesn't build
- Test edge cases (empty states, errors, offline)

## 3. Clean Code & Best Practices — No Technical Debt
- Follow **MVVM + Clean Architecture** strictly
- Use proper naming conventions (Swift API Design Guidelines)
- Keep functions small and single-purpose
- Document public APIs with doc comments
- No force unwraps (`!`) — use guard/if-let
- No magic numbers — use constants from `AppConfig` or design tokens
- Handle all errors gracefully

## 4. Git Always Current
- Commit after every meaningful change
- Use conventional commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Push to GitHub frequently — code should never only live locally
- Branch strategy: work on `main` for MVP (no feature branches needed for solo dev)

## 5. Beautiful & Simple UI/UX
- Follow the approved design system in `FRONTEND_GUIDELINES.md`
- Dark mode premium aesthetic — deep backgrounds, purple accents, glassmorphic elements
- **Simple and straightforward** — don't overcomplicate navigation or flows
- Use SwiftUI exclusively — no UIKit unless absolutely necessary
- Respect iOS HIG (Human Interface Guidelines)
- Accessibility: VoiceOver labels, Dynamic Type, min 44pt touch targets

## 6. Use Packages & Libraries — Don't Reinvent the Wheel
- Use **Supabase Swift SDK** for backend integration
- Use **Lottie** for onboarding animations
- Leverage SwiftUI built-in components (NavigationStack, TabView, sheets)
- Use community packages for beautiful UI elements when available
- Pin exact versions in SPM — no "latest"
- Evaluate packages for: active maintenance, license (MIT/Apache), size

## 7. Ask Before Spending or Breaking Changes
- Never commit to a paid service without explicit user approval
- Ask before changing tech stack decisions
- Ask before adding dependencies > 10MB
- Ask before making destructive database changes
