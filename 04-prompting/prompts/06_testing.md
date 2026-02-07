# Phase 6: Testing Prompts

## Unit Tests

```
Write unit tests for [FILE/MODULE].

Testing framework: [Jest / Vitest]
Coverage target: [80%+ / 90%+]

Follow the patterns in 03-workflows/TESTING.md:
- Arrange → Act → Assert structure
- Mock external services, never the thing being tested
- Import domain entities from source, not through service layers
- Use require() inside mock factories for React Native

Test cases needed:
- Happy path (valid input → expected output)
- Edge cases (empty input, null values, boundary conditions)
- Error cases (invalid input → proper error thrown)
- Async behavior (loading states, timeouts)
```

## Integration Tests

```
Write integration tests for the [FEATURE] user flow.

Flow to test (from APP_FLOW.md):
1. [Step 1]
2. [Step 2]
3. [Step 3]
Expected outcome: [FINAL STATE]

Also test error paths:
- Network offline during step [X]
- Invalid input at step [Y]
- Session expired during step [Z]
```

## Pre-Release Test Run

```
Run the pre-release verification checklist from 03-workflows/TESTING.md:

1. Run tsc --noEmit — report any type errors
2. Run npm test — report pass/fail counts
3. Run npm run lint — report any warnings
4. Check for console.log statements not guarded by __DEV__
5. Verify all imports resolve correctly

Report results in a table format.
```
