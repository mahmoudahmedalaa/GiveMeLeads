# Skill Creator Guide

> How to create reusable AI skills — packaged knowledge that can be loaded on demand.

## What is a Skill?

A skill is a self-contained package of instructions that teaches an AI agent how to perform a specific task. Skills save context window space by loading only what's needed.

## Anatomy of a Skill

```
skill-name/
├── SKILL.md          # Required — Main instructions
├── scripts/          # Optional — Helper scripts
├── references/       # Optional — Documentation, examples
└── assets/           # Optional — Templates, configs
```

## Core Principles

### 1. Conciseness is King
The context window is shared. Every token in your skill is a token not available for code. Write tight.

**Bad**: "When you are creating a new React component, you should first think about..."  
**Good**: "New components: create file → add types → implement → test"

### 2. Progressive Disclosure
Don't dump everything upfront. Structure as:
1. **SKILL.md** — High-level instructions (always loaded)
2. **references/** — Deep detail (loaded on demand)
3. **scripts/** — Automated execution (run when needed)

### 3. Actionable, Not Theoretical
Every sentence should lead to an action. Remove "background" paragraphs.

---

## SKILL.md Template

```markdown
---
name: [Skill Name]
description: [One-line description of what this skill does]
---

# [Skill Name]

## When to Use
[1-2 sentences on when to activate this skill]

## Steps
1. [Concrete action]
2. [Concrete action]
3. [Concrete action]

## Rules
- [Non-negotiable constraint]
- [Non-negotiable constraint]

## References
- See `references/[file]` for [detail topic]

## Verification
- [ ] [How to verify success]
```

---

## Creation Workflow

1. **Identify the pattern** — What task do you repeat across projects?
2. **Draft the steps** — What would you tell a new developer to do?
3. **Strip the fluff** — Remove every sentence that doesn't lead to action
4. **Add verification** — How do you know it worked?
5. **Test it** — Use the skill in a real project
6. **Iterate** — Refine based on what went wrong

---

## Good Skill Examples

| Skill | Purpose | Size |
|:------|:--------|:-----|
| Project Setup | Initialize a new project from template | ~50 lines |
| Firebase Config | Set up Firebase with Compat layer | ~30 lines |
| Auth Flow | Implement email/social authentication | ~60 lines |
| App Store Prep | Prepare metadata for submission | ~40 lines |

## Anti-Patterns

- ❌ Skills longer than 100 lines (too much context)
- ❌ Skills that duplicate docs (reference them instead)
- ❌ Skills without verification steps
- ❌ Generic skills that don't save time over just explaining
