# Testing Strategy

> What to test, how to test, and when to stop. Quality without paralysis.

## Testing Pyramid

```
         ╱ E2E / UAT ╲          ← Few: full user flows
        ╱ Integration  ╲         ← Some: feature flows
       ╱   Unit Tests   ╲       ← Many: logic, validation
      ╱ Type Safety (TSC) ╲     ← Always: compile-time checks
```

---

## Unit Tests

### What to Test
| Priority | Target | Coverage |
|:---------|:-------|:---------|
| Critical | Auth logic, payment flows, data validation | 90%+ |
| High | Business logic, use cases, data transforms | 80%+ |
| Medium | Component rendering (happy path) | 70%+ |
| Low | Static UI, configuration | Optional |

### Structure
```typescript
describe('AuthService', () => {
  describe('login', () => {
    it('should return user on valid credentials', async () => {
      // Arrange
      const credentials = { email: 'test@test.com', password: 'valid' };
      // Act
      const result = await authService.login(credentials);
      // Assert
      expect(result.user).toBeDefined();
      expect(result.user.email).toBe(credentials.email);
    });

    it('should throw on invalid password', async () => {
      // ...
    });
  });
});
```

### Mocking Rules
- Mock external services (APIs, Firebase, storage)
- Never mock the thing being tested
- Use `require` inside mock factories for React Native:
  ```javascript
  jest.mock('moti', () => {
    const { View } = require('react-native');
    return { MotiView: ({ children }) => <View>{children}</View> };
  });
  ```
- Import domain entities from source (`domain/entities/`), not through service layers

---

## Integration Tests

### Key Flows to Cover
1. **Registration → Verification → Login → Home**
2. **Core feature end-to-end** (create → read → update → delete)
3. **Payment flow** (display paywall → purchase → unlock)
4. **Error recovery** (network failure → retry → success)

### Comprehensive Test Suite Pattern
Based on real production experience, structure as 5 categories:
1. **System Stability** — Environment, mocks, core component existence
2. **Feature Logic** — Business rules for each feature
3. **User Flows** — Simulated journeys through the app
4. **Component Health** — Modules load without reference errors
5. **Configuration** — Theme constants, env key structures

---

## User Acceptance Testing (UAT)

### UAT Guide Template

#### Flow: [Feature Name]
1. **Navigate**: [How to reach the feature]
2. **Action**: [What to do]
3. **Expected**: [What should happen]
4. **Edge Cases**:
   - [ ] Network offline → [expected behavior]
   - [ ] Invalid input → [expected error message]
   - [ ] Duplicate action → [expected handling]

### Regression Matrix (150+ Cases)
For production-ready apps, expand testing to cover:

| Area | Cases | Focus |
|:-----|:------|:------|
| First-Time User Experience | ~40 | Onboarding, permissions, anonymous entry |
| Authentication & Security | ~50 | Social login, verification, session persistence |
| Core Features | ~20 | Data integrity, performance under load |
| Monetization | ~20 | Gatekeeping, upgrade flow, restore purchases |
| Performance & UI | ~20 | Animation smoothness, thermal handling, navigation stress |

---

## Logic Isolation Testing

For complex algorithms (text matching, scoring, etc.), test in isolation:

```bash
# Create standalone test script
npx ts-node path/to/verification_script.ts
```

Always include these scenarios:
- ✅ Perfect match
- ✅ Partial match (embedded in longer text)
- ✅ Noisy input (filler words, typos)
- ❌ False positive prevention
- ❌ Wrong sequence (same words, wrong order)

---

## Pre-Commit Checks

```bash
# Run before every commit
npx tsc --noEmit              # Type safety
npm run lint                  # Code quality
npm test -- --passWithNoTests # Tests pass
```
