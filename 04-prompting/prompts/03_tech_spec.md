# Phase 3: Tech Spec Prompts

## Tech Stack Document

```
Create a Technology Stack document for my app.

App Type: [Web / Mobile / Desktop / API]
Platform: [iOS / Android / Web / Cross-platform]
Scale: [MVP / Production]  
Team: [Solo / 2-5 / 5+]
Budget: [Free tier only / $X/month]
Key Features: [LIST FROM PRD]

For EACH technology provide:
- Exact name and version (e.g., "React Native 0.76.9")
- Official docs URL
- Why chosen over alternatives

Include: Framework, Language, Styling, State Management, Database, Auth, Payments, Testing, CI/CD, Hosting.
Plus: .env.example, dependency list (JSON), security rules, upgrade policy.

CRITICAL: Pin exact versions. No "latest".
```

## App Flow Document

```
Create an Application Flow document for my app.

App Type: [Tab-based mobile / SPA / Dashboard]
Main Features: [LIST 3-5]
Auth Required: [Yes / No / Optional]

Generate:
1. Navigation structure (ASCII tree)
2. Screen specs (route, layout wireframe, elements, states)
3. User flows (ASCII flowcharts for: onboarding, core feature, auth, settings)
4. State transitions (auth states, data loading states)
5. Error handling UX (error type → message → action table)
```

## Backend Structure Document

```
Create a Backend Structure document for my app.

Backend: [REST API / Firebase / Supabase / GraphQL]
Database: [PostgreSQL / Firestore / MongoDB]
Auth: [JWT / Firebase Auth / Session]
Features needing DB: [LIST]

Generate: Schema tables (columns, types, constraints, indexes), API endpoints (method, path, body, response, errors), auth levels, error codes, rate limits.
```
