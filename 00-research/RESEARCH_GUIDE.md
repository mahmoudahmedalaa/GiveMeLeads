# Research Guide

> Complete this BEFORE writing your PRD. Bad research = bad product.

## 1. Problem Validation

### What problem are you solving?
Businesses and solopreneurs waste hours manually scrolling through Reddit looking for people who are actively asking for the product/service they offer — missing high-intent leads buried in thousands of posts.

### Who has this problem?
- **Solopreneurs & indie hackers** trying to find their first customers
- **B2B SaaS founders** looking for Reddit-sourced leads
- **Freelancers & consultants** hunting for project opportunities
- **Marketing agencies** managing social selling for clients

### How do they solve it today?
1. **Manual Reddit scrolling** — incredibly time-consuming, hit-or-miss
2. **Google Alerts** — no Reddit support, misses most conversations
3. **F5Bot** — basic free tool, email-only alerts, no scoring or context
4. **GummySearch** — shut down Dec 2025 after Reddit denied API access
5. **Devi AI** — web-based, no native iOS app, $49+/month
6. **Brand24 / Awario** — enterprise-grade, expensive ($79-299/mo), not mobile-first

### Why is the current solution inadequate?
- **No mobile-first experience** — all competitors are web-only dashboards
- **GummySearch gap** — the most popular Reddit-specific tool shut down, leaving a vacuum
- **Expensive** — enterprise tools start at $79/month, overkill for solopreneurs
- **No AI scoring on mobile** — nobody combines lead scoring + mobile convenience
- **Overwhelming** — tools dump raw mentions without prioritizing intent

---

## 2. User Research

### Target User Persona

| Field | Description |
|:---|:---|
| **Name** | "Sam the SaaS Founder" |
| **Age Range** | 25-40 |
| **Occupation** | Indie hacker, SaaS founder, freelancer |
| **Tech Comfort** | High |
| **Primary Device** | iPhone (checks leads on-the-go) |
| **Key Pain Point** | Spends 1-2 hours daily scrolling Reddit for potential customers, misses 90% of relevant posts |
| **Goal** | Get notified of high-intent leads in real-time, respond quickly before competitors do |

### User Interview Questions (if possible)
1. How do you currently find potential customers on Reddit?
2. How much time per day do you spend on social selling?
3. What's the most frustrating part of finding leads on Reddit?
4. Have you paid for any lead generation tool before? What did/didn't work?
5. Would you pay $19/month for AI-filtered, scored Reddit leads on your phone?

---

## 3. Market Analysis

### Market Size
- **TAM**: $15.5B — Global social media management market (2025)
- **SAM**: $2.1B — Social listening & lead generation tools segment
- **SOM**: $5M — iOS-first Reddit lead gen for SMBs/solopreneurs (year 1, ~22K users at $19/mo)

### Trends
- ✅ **Growing**: Reddit's user base hit 1.7B monthly users (2025), increasingly used for purchase decisions
- ✅ **GummySearch vacuum**: Most popular Reddit-specific tool shut down Dec 2025
- ✅ **Mobile-first shift**: Professionals increasingly manage sales from mobile
- ✅ **AI democratization**: Free/cheap AI models make intelligent lead scoring accessible
- ⚠️ **Reddit API changes**: Reddit tightened API access in 2023-2024; need to stay compliant

---

## 4. Technical Feasibility

### Can you build this?
- [x] Required APIs exist and are accessible — Reddit API (free tier available via OAuth)
- [x] No platform restrictions prevent the core feature — Reddit API allows search
- [x] Data sources are available and reliable — Reddit's API is well-documented
- [x] Performance requirements are achievable — Swift + background fetch
- [x] Cost of infrastructure is sustainable — Supabase free tier + free AI models

### Key Technical Risks
| Risk | Severity | Mitigation |
|:---|:---|:---|
| Reddit API rate limits | High | Respect limits, implement caching, batch requests |
| Reddit API access denied (GummySearch precedent) | High | Stay within ToS, use official API only, no scraping |
| Free AI model quality | Medium | Fine-tune prompts, allow user to report bad scores |
| Background refresh on iOS | Medium | Use BGTaskScheduler, respect iOS battery limits |
| App Store rejection | Low | Follow all guidelines, no misleading claims |

---

## 5. Business Model Canvas (MVP)

| Element | Decision |
|:---|:---|
| **Revenue Model** | Subscription (7-day free trial) |
| **Pricing** | $19/month |
| **Key Cost Drivers** | Supabase hosting (~$25/mo at scale), Reddit API (free), AI inference (free/minimal) |
| **Distribution** | App Store (iOS) |
| **Unfair Advantage** | Only native iOS app for Reddit lead gen; fills GummySearch vacuum; AI scoring at $19/mo vs $79+ competitors |

---

## 6. Go / No-Go Decision

- [x] The problem is real and validated — GummySearch had thousands of paying users before shutdown
- [x] My target user is clearly defined — solopreneurs and SaaS founders
- [x] I have a realistic competitive advantage — mobile-first, affordable, post-GummySearch vacuum
- [x] The technical approach is feasible — Reddit API + free AI + Swift
- [x] The business model can sustain the product — $19/mo at 500 users = $9,500 MRR
- [x] I'm willing to commit 4-6 weeks to this

**Decision**: ✅ GO
