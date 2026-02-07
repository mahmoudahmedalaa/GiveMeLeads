# Code Quality Standards

> Non-negotiable standards for all code in this project.

## Architecture

### Clean Architecture (Recommended)
```
domain/        → Entities, use cases, interfaces (zero framework deps)
data/          → Repository implementations, API clients, mappers
presentation/  → Screens, components, view models
infrastructure/ → Auth, storage, config, third-party SDKs
```

**Rule**: Dependencies point inward. `domain/` never imports from `data/` or `presentation/`.

### File Organization
- One component/class per file
- Group by feature, not by type (e.g., `features/auth/` not `components/LoginButton`)
- Barrel exports (`index.ts`) for public APIs only

---

## Naming Conventions

| Entity | Convention | Example |
|:-------|:-----------|:--------|
| Files (components) | PascalCase | `LoginScreen.tsx` |
| Files (utilities) | camelCase | `formatDate.ts` |
| Files (tests) | Match + suffix | `LoginScreen.test.tsx` |
| Variables | camelCase | `currentUser` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Types/Interfaces | PascalCase | `User`, `IAuthRepository` |
| Components | PascalCase | `<NoteCard />` |
| CSS classes | kebab-case | `.note-card` |
| DB columns | snake_case | `created_at` |
| API endpoints | kebab-case | `/api/user-notes` |

---

## TypeScript Rules

- **Strict mode**: Always enabled (`"strict": true`)
- **No `any`**: Use `unknown` + type narrowing instead
- **No implicit returns**: All functions declare return types
- **No magic numbers**: Use named constants
- **Import paths**: Use absolute imports or path aliases — no `../../../`

---

## Testing Requirements

### What to Test
| Priority | What | Coverage Target |
|:---------|:-----|:---------------|
| **Critical** | Auth logic, payment flows | 90%+ |
| **High** | Business logic, validations | 80%+ |
| **Medium** | UI components (happy path) | 70%+ |
| **Low** | Pure UI, static screens | Optional |

### Test Structure
```typescript
describe('ComponentName', () => {
  describe('when [condition]', () => {
    it('should [expected behavior]', () => {
      // Arrange → Act → Assert
    });
  });
});
```

### Mocking Rules
- Mock external services (APIs, Firebase, etc.)
- Never mock the thing you're testing
- Use `require` inside mock factories to avoid hoisting issues
- Import domain entities from their source, not through intermediate layers

---

## Code Review Checklist

Before considering any feature "done":

- [ ] All TypeScript errors resolved (`tsc --noEmit`)
- [ ] No lint warnings (`eslint .`)
- [ ] Tests pass (`npm test`)
- [ ] No `console.log` (use `__DEV__` guard or remove)
- [ ] Error states handled (loading, empty, error)
- [ ] No hardcoded strings (use constants or i18n)
- [ ] Accessibility: focus states, aria labels, semantic HTML
- [ ] No secrets in code (use env vars)

---

## Import Hygiene

### Common Pitfalls
1. **Broken relative paths**: Always verify imports after moving files
2. **Missing exports**: Run `tsc --noEmit` to catch
3. **Circular dependencies**: Domain layer must never import from data/presentation
4. **Stale mocks**: Test mocks must match current domain entity shapes

### Build Verification
Run before every commit:
```bash
npx tsc --noEmit          # Catch type errors
npm run lint              # Catch style issues
npm test -- --passWithNoTests  # Catch logic errors
```
