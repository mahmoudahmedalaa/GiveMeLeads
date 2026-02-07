# Technology Stack

> Every technology decision locked down with exact versions. No "latest" — pin everything.

## 1. Stack Overview

| Dimension | Decision | Justification |
|:----------|:---------|:--------------|
| **Architecture** | [Monolithic / Clean Architecture / Microservices] | |
| **Platform** | [iOS / Android / Web / Cross-platform] | |
| **Deployment** | [App Store / Vercel / AWS / Railway] | |
| **Scale Target** | [MVP / 1K users / 100K users] | |

---

## 2. Frontend Stack

| Technology | Version | Purpose | Docs | Alternative Considered |
|:-----------|:--------|:--------|:-----|:-----------------------|
| **Framework** | | | | |
| **Language** | TypeScript X.X | Type safety | | |
| **Styling** | | | | |
| **State Mgmt** | | | | |
| **Navigation** | | | | |
| **Forms** | | | | |
| **UI Library** | | | | |
| **Animations** | | | | |

---

## 3. Backend Stack

| Technology | Version | Purpose | Docs | Alternative Considered |
|:-----------|:--------|:--------|:-----|:-----------------------|
| **Runtime** | | | | |
| **Database** | | | | |
| **Auth** | | | | |
| **File Storage** | | | | |
| **Email** | | | | |
| **Payments** | | | | |
| **Analytics** | | | | |

---

## 4. Development Tools

| Tool | Version | Purpose |
|:-----|:--------|:--------|
| **Package Manager** | npm / pnpm / yarn | |
| **Linter** | ESLint X.X | Code quality |
| **Formatter** | Prettier X.X | Consistent formatting |
| **Git Hooks** | Husky X.X | Pre-commit checks |
| **Testing** | Jest / Vitest X.X | Unit tests |
| **E2E Testing** | Playwright / Detox X.X | Integration tests |

---

## 5. Environment Variables

```bash
# Application
APP_NAME="your-app"
APP_ENV="development"  # development | staging | production

# Database
DATABASE_URL="postgresql://..."

# Authentication
AUTH_SECRET="generate-a-secure-secret"
# OAUTH_CLIENT_ID="..."

# Third-Party Services
# API_KEY="..."

# Feature Flags
# ENABLE_PREMIUM=true
```

> ⚠️ Never commit `.env` files. Use `.env.example` as a template.

---

## 6. Dependencies Lock

### Frontend
```json
{
  "dependency-name": "X.X.X"
}
```

### Backend
```json
{
  "dependency-name": "X.X.X"
}
```

> Pin exact versions. Run `npm audit` monthly.

---

## 7. Security Considerations

| Area | Approach |
|:-----|:---------|
| **Authentication** | [JWT / Session / OAuth] with [expiry times] |
| **Passwords** | bcrypt with 12 rounds minimum |
| **API Security** | HTTPS only, CORS configured per domain |
| **Rate Limiting** | Login: 5/15min, API: 100/min |
| **Data Protection** | Encryption at rest, sanitized inputs |
| **Secrets** | Never in code — always env vars |

---

## 8. Version Upgrade Policy

| Type | Frequency | Process |
|:-----|:----------|:--------|
| **Major** | Quarterly review | Test in staging → compatibility check → rollback plan |
| **Minor/Patch** | Monthly | Automated via Dependabot → review weekly |
| **Security** | ASAP | Emergency patch process |

---

## AI Generation Prompt

```
Create a Technology Stack document for [YOUR APP].

App Context:
- Type: [Web app / Mobile / Desktop / API]
- Platform: [iOS / Android / Web / Cross-platform]
- Scale: [MVP / Small / Medium / Enterprise]
- Team Size: [Solo / 2-5 / 5+]
- Timeline: [MVP date]
- Budget: [Free tier only / $X/month]

For EACH technology, provide:
- Exact name and version (e.g., "React Native 0.76.9" not "React Native latest")
- Official documentation URL
- Reason for selection over alternatives
- One alternative considered and why rejected

Required decisions:
- Framework, Language, Styling, State Management
- Database, Auth, File Storage, Payments
- Testing, Linting, CI/CD
- Hosting/Deployment

Also generate:
- Complete .env.example template
- Dependencies with exact versions (JSON format)
- Security considerations table
- Version upgrade policy

CRITICAL: NO "latest" versions. Pin everything.
```
