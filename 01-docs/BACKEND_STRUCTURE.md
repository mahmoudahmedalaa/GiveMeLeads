# Backend Architecture & Database Structure

> Database schema, API contracts, auth logic. Every table, relationship, and endpoint documented before writing code.

## 1. Architecture Overview

| Dimension | Decision |
|:----------|:---------|
| **Pattern** | [REST API / GraphQL / BaaS (Firebase)] |
| **Auth Strategy** | [JWT / Session / Firebase Auth / OAuth] |
| **Data Flow** | Client → API → Business Logic → Database |
| **Caching** | [Redis / In-memory / CDN / None for MVP] |

---

## 2. Database Schema

### Database: [PostgreSQL X.X / Firestore / MongoDB]
- **ORM**: [Prisma / TypeORM / None (BaaS)]
- **Naming**: snake_case for tables/columns
- **Timestamps**: All tables include `created_at`, `updated_at`

### Entity Relationship Diagram
```
[Users] ──1:N──→ [Posts]
[Users] ──1:N──→ [Comments]
[Posts]  ──1:N──→ [Comments]
[Users] ──N:M──→ [Posts] via [Likes]
```

### Table: `users`

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| id | UUID | PK, DEFAULT uuid_v4() | Unique identifier |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Login email |
| password_hash | VARCHAR(255) | NOT NULL | Bcrypt (12 rounds) |
| display_name | VARCHAR(255) | NOT NULL | Public name |
| avatar_url | TEXT | NULL | Profile image URL |
| role | ENUM('user','admin') | DEFAULT 'user' | Auth level |
| created_at | TIMESTAMP | DEFAULT NOW() | |
| updated_at | TIMESTAMP | DEFAULT NOW() | |

**Indexes**: `idx_users_email` ON (email)

### Table: [your_entity]

<!-- Copy the table format above for each entity -->

---

## 3. API Endpoints

### Authentication

#### POST `/api/auth/register`
- **Access**: Public
- **Body**: `{ email, password, display_name }`
- **Validation**: email (valid format, unique), password (min 8 chars), name (2-255 chars)
- **Response 201**: `{ user: { id, email, display_name } }`
- **Errors**: 400 (validation), 409 (email exists)
- **Side Effects**: Create user, send verification email

#### POST `/api/auth/login`
- **Access**: Public
- **Body**: `{ email, password }`
- **Response 200**: `{ access_token, refresh_token, user }`
- **Errors**: 401 (invalid credentials), 403 (unverified email), 429 (rate limited)
- **Side Effects**: Update `last_login_at`, create session

#### POST `/api/auth/refresh`
- **Access**: Authenticated (refresh token)
- **Response 200**: `{ access_token }`
- **Errors**: 401 (expired/invalid token)

### Core Resources

#### GET `/api/[resources]`
- **Access**: [Public / Authenticated]
- **Query Params**: `page`, `limit`, `sort`
- **Response 200**: `{ data: [...], pagination: { page, limit, total, pages } }`
- **Caching**: key `resources:list:page:{page}`, TTL 5 min

#### POST `/api/[resources]`
- **Access**: Authenticated
- **Body**: `{ ... }`
- **Validation**: [field rules]
- **Response 201**: `{ data: { ... } }`
- **Errors**: 400 (validation), 401 (unauthorized)

#### GET `/api/[resources]/:id`
#### PUT `/api/[resources]/:id`
#### DELETE `/api/[resources]/:id`

---

## 4. Authentication & Authorization

### Token Structure (JWT)
- **Access Token**: 15 min expiry — `{ sub, email, role, iat, exp }`
- **Refresh Token**: 7 day expiry — `{ sub, session_id, iat, exp }`

### Authorization Levels
| Level | Routes | Required |
|:------|:-------|:---------|
| **Public** | GET /resources, auth endpoints | Nothing |
| **Authenticated** | POST/PUT/DELETE resources | Valid access token |
| **Admin** | User management, bulk operations | role: admin |

---

## 5. Error Handling

### Standard Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [{ "field": "email", "message": "Already exists" }]
  }
}
```

### Error Codes
| Code | HTTP | When |
|:-----|:-----|:-----|
| VALIDATION_ERROR | 400 | Invalid input |
| UNAUTHORIZED | 401 | Missing/expired token |
| FORBIDDEN | 403 | Insufficient permissions |
| NOT_FOUND | 404 | Resource doesn't exist |
| CONFLICT | 409 | Duplicate / state conflict |
| RATE_LIMITED | 429 | Too many requests |
| SERVER_ERROR | 500 | Unexpected failure |

---

## 6. Security

| Measure | Implementation |
|:--------|:---------------|
| **Passwords** | bcrypt, 12 salt rounds, never returned in API |
| **Rate Limiting** | Login: 5/15min, Register: 3/hr, API: 100/min |
| **Input Sanitization** | Strip HTML, allow markdown, enforce max lengths |
| **CORS** | Configured per environment |
| **Data Encryption** | At rest (DB) and in transit (HTTPS) |

---

## AI Generation Prompt

```
Create a Backend Structure document for [YOUR APP].

Backend Type: [REST API / BaaS (Firebase/Supabase) / GraphQL]
Database: [PostgreSQL / Firestore / MongoDB]
Auth Strategy: [JWT / Firebase Auth / Session]
Main Features: [LIST FEATURES THAT NEED DATABASE SUPPORT]

Generate:
1. SCHEMA: For each table — all columns with exact types, constraints, indexes, relationships. Use markdown tables.
2. API ENDPOINTS: For each endpoint — method, path, access level, request body (JSON), validation rules, response (JSON), error codes, side effects, caching.
3. AUTH: Token structure, authorization levels, password security.
4. ERROR HANDLING: Standard error format and code table.
5. SECURITY: Rate limiting, input sanitization, CORS, encryption.

CRITICAL: Exact data types with lengths. ALL constraints and indexes. Complete request/response examples.
```
