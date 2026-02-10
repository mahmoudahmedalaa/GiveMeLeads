---
description: Autonomous development loop - Develop, Test, Improve until feature excellence
---

# Develop-Test-Improve Loop

This workflow ensures feature excellence through autonomous iteration. Apply this to every feature you build.

## The Loop

### 1. Develop
- Implement the feature fully (backend + frontend)
- Write clean, production-quality code
- Follow existing patterns and conventions

### 2. Build & Test
// turbo
- Run `xcodegen generate && xcodebuild -project *.xcodeproj -scheme * -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -10`
- Fix any compilation errors immediately

### 3. Self-Evaluate
Ask yourself these questions:
- **User Value**: Does this feature genuinely help the user achieve their goal?
- **Clarity**: Would a first-time user understand what to do without explanation?
- **Quality Bar**: Would a paying customer be satisfied with this experience?
- **Edge Cases**: What happens with no data? Bad data? Slow network?
- **Design**: Does the UI feel premium and action-oriented, not just functional?

### 4. Improve
Based on self-evaluation:
- Fix any issues found
- Polish the UX (micro-copy, loading states, empty states)
- Improve precision and reduce noise
- Add missing context that guides the user

### 5. Re-Test
// turbo
- Build again to verify improvements compile
- Review the full user journey end-to-end

### 6. Repeat or Ship
- If not satisfied → go back to step 3
- If satisfied → write walkthrough and notify user

## Key Principles

1. **Precision > Volume**: 5 high-quality leads beat 50 irrelevant ones
2. **Guide > Dump**: Tell the user WHY and HOW, don't just show raw data
3. **Action > Information**: Every screen should drive a clear next action
4. **Test from the user's perspective**, not the developer's
5. **Quality gate**: If you wouldn't pay to use it, keep improving
