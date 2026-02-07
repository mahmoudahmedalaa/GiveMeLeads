# 🚀 Project Template

A battle-tested project template for building production-grade apps with AI-first development. Born from real shipping experience — every checklist item exists because something went wrong without it.

## Philosophy

**You describe your idea. The AI builds it.** The template ensures nothing gets missed.

---

## How to Use This Template

### Step 1: Copy
Copy this entire `template/` folder into your new project directory.

### Step 2: Start a Conversation
Open a conversation with your AI agent and say:

> I want to build **[your idea in 1-2 sentences]**.
>
> Read `AGENTS.md` first, then follow the workflow it describes.

That's it. The `AGENTS.md` file tells the agent to read the entire template, absorb the rules, and then drive the process.

### Step 3: Answer Questions
Your AI will interview you about your idea, users, goals, and preferences. Based on your answers, it generates all the documentation and then builds the app.

---

## What's Your Role vs. The AI's Role

```
┌──────────────────────────────────────────────────────────────┐
│  PHASE A — You participate (answer questions & review)       │
│                                                              │
│  00-research/  →  AI asks about your market, users, problem  │
│  01-docs/      →  AI interviews you → generates all docs     │
│  MCP Discovery →  AI recommends tools, asks you to enable    │
├──────────────────────────────────────────────────────────────┤
│  PHASE B — AI works autonomously (you step away)             │
│                                                              │
│  02-agent/     →  AI reads its own operating rules           │
│  03-workflows/ →  AI follows dev, test, deploy procedures    │
│  04-prompting/ →  AI references lessons & best practices     │
│  05-checklists/→  AI verifies everything before shipping     │
└──────────────────────────────────────────────────────────────┘
```

### You do:
- Describe your idea
- Answer the AI's research & requirements questions
- Review generated documentation
- Approve MCP integrations
- Open new chat windows for each major task (for max AI quality)

### The AI does:
- Research your market and competitors
- Generate PRD, flows, tech spec, design system, backend spec, build plan
- Set up MCP integrations
- Decompose the build into self-contained tasks
- Implement, test, and deploy

---

## Folder Structure

```
template/
├── AGENTS.md             → 🚀 Entry point — AI reads this first
├── 00-research/          → Market research & competitor analysis
├── 01-docs/              → 6 documentation templates
├── 02-agent/             → AI operating rules, skills, autonomy
├── 03-workflows/         → Dev, testing, deployment procedures
├── 04-prompting/         → Lessons learned & reference guides
│   └── prompts/          → Fallback for non-agentic AIs only
└── 05-checklists/        → Launch & post-launch checklists
```

---

## Fresh Context Strategy (Ralph Wiggum Loop)

For maximum AI quality, use **one conversation per major task**:

1. During Phase A, the AI generates a detailed **task list** from the Implementation Plan
2. Each task is self-contained with all the context the AI needs
3. **Open a new conversation for each task** → full context window → best output
4. Each conversation starts with: *"Read AGENTS.md, then execute Task [N] from `01-docs/IMPLEMENTATION_PLAN.md`"*
5. After each task, the AI verifies (tests, lint, type-check) and iterates until passing

This gives you the benefits of autonomous AI coding with maximum quality per task.

---

## Key Principles

- **You talk, the agent works** — describe your idea, the templates guide everything
- **Fresh contexts** — new conversation per task = maximum AI quality
- **Nothing skipped** — numbered phases enforce correct order
- **Battle tested** — every checklist item learned the hard way
- **Self-improving** — update `04-prompting/LESSONS_LEARNED.md` after each project
