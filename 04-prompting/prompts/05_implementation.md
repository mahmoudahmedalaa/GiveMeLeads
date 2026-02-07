# Phase 5: Implementation Prompts

## Feature Implementation

```
Implement [FEATURE NAME] for my project.

Read these docs first:
- 01-docs/PRD.md — Feature [N]: [Feature Name]
- 01-docs/APP_FLOW.md — Screen [X] and Flow [Y]
- 01-docs/TECH_STACK.md — Relevant technologies
- 01-docs/FRONTEND_GUIDELINES.md — Component specs
- 01-docs/BACKEND_STRUCTURE.md — API endpoint [Z]

Follow IMPLEMENTATION_PLAN.md Step [4.X].

Implementation order:
1. Data layer (repository/API client)
2. Business logic (use case)
3. UI component
4. Connect layers
5. Handle all states (loading, empty, error, success)
6. Add TypeScript types

Do not deviate from the specifications. Ask if anything is ambiguous.
```

## Referencing Existing Code

```
I need to implement [NEW FEATURE] that follows the same pattern as [EXISTING FEATURE].

Look at these reference files:
- [path/to/existing/implementation]

Create the new feature following the exact same:
- File structure
- Naming conventions
- Error handling patterns
- TypeScript types

New feature requirements:
- [Specific requirement 1]
- [Specific requirement 2]
```

## Debugging

```
I'm getting this error: [PASTE ERROR MESSAGE]

Context:
- File: [FILENAME]
- What I was doing: [ACTION]
- What I expected: [EXPECTED BEHAVIOR]
- What happened: [ACTUAL BEHAVIOR]

Check 03-workflows/TROUBLESHOOTING.md first — this might be a known issue.
If not, diagnose the root cause (not just the symptom) and fix it.
```
