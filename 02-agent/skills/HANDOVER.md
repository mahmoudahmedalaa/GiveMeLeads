---
description: Generates a comprehensive handover summary for the next AI session, detailing project context, recent changes, active issues, and next steps.
---

# Handover Protocol

**Skill Objective**: To create a complete, high-context transfer of knowledge to the next AI agent so they can immediately become productive without re-reading thousands of lines of chat history.

## When to Use
- At the end of a significant development session.
- Before switching tasks or "ending the day".
- When you (the AI) feel context is getting too heavy and a fresh start is needed.
- When the USER explicitly asks for a "handover".

## Protocol Steps

### 1. Context Analysis
Scan the following to build your mental model:
- **Project Identity**: `README.md`, `01-docs/PRD.md` (What is this?)
- **Current Status**: `git status`, `git log -n 5` (What just happened?)
- **Active Plans**: `01-docs/IMPLEMENTATION_PLAN.md`, `task.md` (What's next?)
- **Known Issues**: Open bugs, failing tests, or manual `FIXME` comments.

### 2. Generate Handover Report
Create a markdown artifact named `HANDOVER_REPORT.md` (or output directly to chat if brief) with the following structure:

#### 1. 📋 Project Snapshot
- **Name & Purpose**: One-line pitch.
- **Phase**: (e.g., "Phase 4: Feature Implementation", "Post-Launch Maintenance").
- **Key Tech Stack**: (e.g., React Native + Expo, Node.js, Firebase).

#### 2. 🚧 Context & Recent Activity
- **Last Task**: What was just completed? (e.g., "Fixed battery drain in audio player").
- **Active Branch**: Which branch are we on? (`fix/battery-optimization`? `main`?).
- **Uncommitted Changes**: Are there files in staging? (Check `git status`).

#### 3. 🚨 Critical Issues & Blockers
- **Bugs**: Any known crashing bugs or high-severity issues?
- **Blockers**: Waiting on API keys? Waiting on App Store review?
- **Performance**: Any known slow areas (e.g., "Audio list rendering is laggy").

#### 4. ⏭️ Immediate Next Actions (The "To-Do" List)
- **Action 1**: The very first thing the next AI should do.
- **Action 2**: The follow-up.
- **Action 3**: Long-term/next-milestone item.

*Tip: Be specific. Instead of "Fix bugs", say "Debug race condition in `useAudioPlayer.ts` line 45".*

#### 5. 🧠 "Brain Dump" / Architectural Decisions
- **Why we did X**: (e.g., "We chose `expo-av` over `react-native-track-player` because...").
- **Gotchas**: (e.g., "Remember to run `npx expo prebuild` if you change native permissions").
- **Secrets**: (e.g., "API keys are in `.env`, do not commit them").

---

## Example Output

```markdown
# 🚀 Handover Report: QuranNotes App

**Phase**: Post-Launch Polish (v1.0.1 Pending)
**Branch**: `fix/battery-optimization`

### 🚧 Recent Activity
- **Fixed critical battery drain**: Replaced infinite progress animation in `StickyAudioPlayer` with actual progress tracking.
- **Throttled Audio Updates**: Reduced `AudioPlayerService` updates from 60fps to 1fps.
- **Status**: Code is committed and tested locally.

### 🚨 Critical State
- **Live App (v1.0.0)**: Currently **In Review** by Apple. DO NOT CANCEL.
- **Battery Fix (v1.0.1)**: Ready on branch `fix/battery-optimization`. Waiting for v1.0.0 approval to merge and ship.

### ⏭️ Next Actions
1. **Monitor App Store Connect**: Check if v1.0.0 is approved.
2. **Ship v1.0.1**: Once approved -> Merge branch -> Bump version -> `eas submit`.
3. **Verify**: Test battery usage on real device after update.
```
