# AI Prompting Playbook

> Reference guide for how your AI agent interacts with this template. You don't need to do anything here manually — the agent reads this.

## How the Template Works

**You describe your idea. The agent does the rest.** Here's what happens:

1. Agent reads `00-research/` → asks you about your market, users, competitors
2. Agent reads `01-docs/` templates → interviews you → generates filled documentation
3. Agent reads `02-agent/` → configures its own operating rules
4. Agent follows `03-workflows/` → builds, tests, deploys
5. Agent runs `05-checklists/` → verifies everything before shipping

The templates in `01-docs/` are **structure guides** — they tell the agent what sections a good PRD, App Flow, etc. should have, and what questions to ask you.

---

## Effective Collaboration Tips

### Give the Agent Context
**Instead of**: "Build a login page"  
**Say**: "Implement the login screen. Refer to `01-docs/APP_FLOW.md` for the flow and `01-docs/FRONTEND_GUIDELINES.md` for the design."

### Let Docs Drive Decisions
After the research and documentation phases are complete, the agent should reference these docs for every implementation decision — not make assumptions.

### Iterate Small
Work in small, testable steps:
1. "Implement the data layer for this feature"
2. "Now build the UI"
3. "Connect them"
4. "Add error handling"
5. "Add tests"

### Verify Before Moving On
After each step, the agent should:
- Run `tsc --noEmit` (catch type errors)
- Run tests (catch logic errors)
- Test on device/browser (catch UX issues)

---

## When Things Go Wrong

1. **Stop** — don't let the agent continue on a wrong path
2. **Point to docs** — "Re-read `01-docs/APP_FLOW.md` Section 2.3"
3. **Constrain** — "Only modify this one file"
4. **Verify** — "Show me the diff before applying"

---

## Autonomy Guidelines

| Situation | Agent Should |
|:----------|:------------|
| Implementing a documented feature | ✅ Act autonomously |
| Fixing a clear bug | ✅ Act autonomously |
| Adding a new dependency | ⚠️ Explain first, then act |
| Changing architecture | 🛑 Ask you before acting |
| Anything not in the docs | 🛑 Ask you before acting |

See `02-agent/rules/AUTONOMY.md` for the full decision matrix.

---

## Fallback: Manual Prompts

If you're using an AI that **cannot read project files** (e.g., ChatGPT web), see `prompts/` for copy-paste prompt templates. Otherwise, ignore that folder entirely.
