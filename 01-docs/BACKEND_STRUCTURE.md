# Backend Architecture & Database Structure

> Database schema, API contracts, auth logic. Every table, relationship, and endpoint documented before writing code.

## 1. Architecture Overview

| Dimension | Decision |
|:----------|:---------|
| **Pattern** | BaaS (Supabase) + Edge Functions |
| **Auth Strategy** | Supabase Auth (JWT) + Sign in with Apple |
| **Data Flow** | iOS App → Supabase Client SDK → PostgreSQL (RLS) |
| **Caching** | SwiftData local cache for offline reading |
| **Background Jobs** | Supabase Edge Functions (cron via pg_cron) |

---

## 2. Database Schema

### Database: PostgreSQL 15 (via Supabase)
- **ORM**: None (Supabase client SDK with PostgREST)
- **Naming**: snake_case for tables/columns
- **Timestamps**: All tables include `created_at`, `updated_at`
- **Security**: Row Level Security (RLS) on all tables

### Entity Relationship Diagram
```
[users] ──1:N──→ [tracking_profiles]
[tracking_profiles] ──1:N──→ [keywords]
[users] ──1:N──→ [leads]
[keywords] ──1:N──→ [leads]
[leads] ──1:N──→ [ai_replies]
```

---

### Table: `users`

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| id | UUID | PK, FK → auth.users(id) | Supabase Auth user ID |
| email | VARCHAR(255) | NOT NULL | From auth |
| display_name | VARCHAR(100) | NULL | Optional display name |
| product_description | TEXT | NULL | "What do you offer?" for AI context |
| trial_ends_at | TIMESTAMP WITH TZ | NOT NULL | Trial expiry (signup + 7 days) |
| subscription_status | VARCHAR(20) | DEFAULT 'trial' | trial / active / expired / cancelled |
| notification_score_threshold | INTEGER | DEFAULT 80 | Min score for push notifications |
| max_notifications_per_day | INTEGER | DEFAULT 10 | Notification cap |
| created_at | TIMESTAMP WITH TZ | DEFAULT NOW() | |
| updated_at | TIMESTAMP WITH TZ | DEFAULT NOW() | |

**Indexes**: `idx_users_email` ON (email), `idx_users_subscription` ON (subscription_status)  
**RLS**: Users can only read/update their own row.

---

### Table: `tracking_profiles`

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | |
| user_id | UUID | FK → users(id), NOT NULL | Owner |
| name | VARCHAR(100) | NOT NULL | "My SaaS", "Freelance" |
| subreddits | TEXT[] | DEFAULT '{}' | e.g., ['SaaS', 'productivity'] |
| is_active | BOOLEAN | DEFAULT true | Toggle on/off |
| created_at | TIMESTAMP WITH TZ | DEFAULT NOW() | |
| updated_at | TIMESTAMP WITH TZ | DEFAULT NOW() | |

**Indexes**: `idx_profiles_user` ON (user_id)  
**RLS**: Users can only CRUD their own profiles. Max 3 per user (enforced in app).

---

### Table: `keywords`

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | |
| profile_id | UUID | FK → tracking_profiles(id) ON DELETE CASCADE | Parent profile |
| user_id | UUID | FK → users(id), NOT NULL | Denormalized for RLS |
| keyword | VARCHAR(50) | NOT NULL | Search term |
| is_exact_match | BOOLEAN | DEFAULT false | Quoted exact match |
| created_at | TIMESTAMP WITH TZ | DEFAULT NOW() | |

**Indexes**: `idx_keywords_profile` ON (profile_id), `idx_keywords_user` ON (user_id)  
**Constraints**: UNIQUE(profile_id, keyword). Max 10 per profile (enforced in app).  
**RLS**: Users can only CRUD their own keywords.

---

### Table: `leads`

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | |
| user_id | UUID | FK → users(id), NOT NULL | Owner |
| keyword_id | UUID | FK → keywords(id), NULL | Which keyword matched |
| reddit_post_id | VARCHAR(20) | NOT NULL | Reddit's post ID (e.g., "t3_abc123") |
| subreddit | VARCHAR(100) | NOT NULL | e.g., "SaaS" |
| author | VARCHAR(50) | NOT NULL | Reddit username |
| title | TEXT | NOT NULL | Post title |
| body | TEXT | NULL | Post body (may be empty for link posts) |
| url | TEXT | NOT NULL | Reddit URL |
| score | INTEGER | NULL | AI intent score 0-100 |
| score_breakdown | JSONB | NULL | `{"intent": 85, "urgency": 70, "fit": 90}` |
| upvotes | INTEGER | DEFAULT 0 | Reddit upvotes |
| comment_count | INTEGER | DEFAULT 0 | Reddit comment count |
| status | VARCHAR(20) | DEFAULT 'new' | new / saved / contacted / dismissed / converted |
| posted_at | TIMESTAMP WITH TZ | NOT NULL | When posted on Reddit |
| discovered_at | TIMESTAMP WITH TZ | DEFAULT NOW() | When we found it |

**Indexes**: 
- `idx_leads_user_status` ON (user_id, status)
- `idx_leads_user_score` ON (user_id, score DESC)
- `idx_leads_reddit_id` ON (user_id, reddit_post_id) UNIQUE

**RLS**: Users can only access their own leads.

---

### Table: `ai_replies`

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | |
| lead_id | UUID | FK → leads(id) ON DELETE CASCADE | |
| user_id | UUID | FK → users(id), NOT NULL | Denormalized for RLS |
| tone | VARCHAR(20) | NOT NULL | professional / casual / helpful |
| suggestion | TEXT | NOT NULL | Generated reply text |
| created_at | TIMESTAMP WITH TZ | DEFAULT NOW() | |

**Indexes**: `idx_replies_lead` ON (lead_id)  
**RLS**: Users can only access their own replies.

---

## 3. Supabase Edge Functions

### Function: `scan-reddit`
- **Trigger**: pg_cron every 30 minutes
- **Purpose**: Fetch Reddit posts matching user keywords
- **Logic**:
  1. Query all active keywords with their profiles
  2. For each unique keyword, search Reddit API
  3. Filter results by subreddit (if specified)
  4. Insert new leads (skip duplicates via UNIQUE constraint)
  5. Trigger lead scoring for new leads
- **Rate Limits**: Respect Reddit's 60 req/min; batch users

### Function: `score-lead`
- **Trigger**: Database webhook on `leads` INSERT
- **Purpose**: Score new leads using NL heuristics
- **Logic**:
  1. Analyze post title + body for intent signals
  2. Check for: asking for recommendations, expressing frustration, comparing options, urgency words
  3. Calculate score 0-100 with breakdown
  4. Update lead row with score + breakdown
- **Scoring Heuristics** (free, no API needed):
  - +20: Contains "recommend", "suggest", "looking for"
  - +15: Contains "need", "want", "searching"
  - +15: Contains "alternative to", "instead of", "replace"
  - +10: Contains "help", "advice", "best"
  - +10: Contains urgency words ("asap", "urgent", "soon")
  - +10: High engagement (upvotes > 10 or comments > 5)
  - +10: Posted recently (< 6 hours)
  - +10: Question format (contains "?")
  - -10: Clearly off-topic or meta post
  - Cap at 100, floor at 0

### Function: `generate-replies`
- **Trigger**: On-demand (user requests)
- **Purpose**: Generate AI reply suggestions
- **Logic**:
  1. Receive lead_id and user's product_description
  2. Call free Hugging Face inference API (or fallback to templates)
  3. Generate 3 replies: professional, casual, helpful
  4. Insert into `ai_replies` table
- **Fallback Templates** (if AI unavailable):
  - Professional: "Hi! Based on what you're describing, you might want to check out [product]. It handles [pain point] well."
  - Casual: "Hey! I've been using [product] for exactly this — works great for [use case]."
  - Helpful: "I had the same challenge and found [product] really helpful. Happy to share more details if you're interested!"

---

## 4. Authentication & Authorization

### Supabase Auth
- **Sign in with Apple**: Required for App Store apps with IAP
- **Email/Password**: Standard Supabase Auth flow
- **Access Token**: 1hr expiry (auto-refreshed by SDK)
- **Refresh Token**: 7-day expiry

### Authorization via RLS
| Level | Description | Implementation |
|:------|:-----------|:---------------|
| **Authenticated** | Basic access to own data | `auth.uid() = user_id` |
| **Trial Active** | Full feature access | Check `trial_ends_at > NOW()` in app |
| **Subscribed** | Full feature access | Check `subscription_status = 'active'` in app |
| **Limited** | Read-only after trial | Enforced in app UI (not backend) |

---

## 5. Error Handling

### Standard Error Response (Edge Functions)
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Keyword cannot be empty",
    "details": [{ "field": "keyword", "message": "Required" }]
  }
}
```

### Error Codes
| Code | HTTP | When |
|:-----|:-----|:-----|
| VALIDATION_ERROR | 400 | Invalid input |
| UNAUTHORIZED | 401 | Missing/expired token |
| FORBIDDEN | 403 | Trial expired + trying to write |
| NOT_FOUND | 404 | Lead/profile doesn't exist |
| CONFLICT | 409 | Duplicate keyword |
| RATE_LIMITED | 429 | Too many requests |
| REDDIT_API_ERROR | 502 | Reddit API unavailable |
| SERVER_ERROR | 500 | Unexpected failure |

---

## 6. Security

| Measure | Implementation |
|:--------|:---------------|
| **Authentication** | Supabase Auth (JWT), managed by SDK |
| **Authorization** | Row Level Security on ALL tables |
| **Rate Limiting** | Supabase default + Reddit API respect |
| **Input Validation** | Server-side: max keyword length, profile limits |
| **HTTPS** | Enforced by Supabase + iOS ATS |
| **Secrets** | Edge Function env vars, never in client |
| **Reddit OAuth** | Server-side only, user never sees Reddit creds |
