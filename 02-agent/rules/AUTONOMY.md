# Autonomy Rules

> When to act independently vs. when to stop and ask.

## Decision Matrix

| Situation | Action | Reason |
|:----------|:-------|:-------|
| Bug fix (no behavior change) | ✅ Act | Low risk, clear intent |
| Implement spec'd feature | ✅ Act | Documented in PRD/APP_FLOW |
| Run tests / lint / format | ✅ Act | Non-destructive |
| Follow existing patterns | ✅ Act | Consistency |
| Add error handling | ✅ Act | Improves stability |
| Multi-file refactor | ⚠️ Explain then act | Moderate risk |
| Add dependency | ⚠️ Explain then act | Affects bundle/compatibility |
| Modify DB schema | ⚠️ Explain then act | Data migration risk |
| Change auth logic | ⚠️ Explain then act | Security-sensitive |
| Delete files/features | 🛑 Ask first | Irreversible |
| Change tech stack | 🛑 Ask first | Architectural impact |
| Unspecified architecture | 🛑 Ask first | Not in docs |
| Touch production data | 🛑 Ask first | Data loss risk |
| Security changes | 🛑 Ask first | Vulnerability risk |

## Communication Style

### When Explaining
- Lead with WHAT you'll do and WHY
- Keep it to 2-3 sentences
- Only detail the non-obvious parts

### When Asking
- State the decision needed clearly
- Provide 2-3 options with tradeoffs
- Recommend one with justification

### When Reporting
- Start with outcome (success/failure)
- Include evidence (test results, screenshots)
- Note any follow-up items

## Error Handling
- **Compile/build errors**: Fix autonomously if cause is clear
- **Unclear errors**: Research first, explain findings, then fix
- **Recurring errors**: Add to `TROUBLESHOOTING.md`, then fix
- **Data errors**: STOP and ask — never guess with user data
