---
name: MCP Setup
description: Discover and configure MCP (Model Context Protocol) servers for your project
---

# MCP Setup

## When to Use
During **Phase A, Step 3** (after Tech Stack is decided). The AI recommends relevant MCP servers based on the chosen stack and helps the user enable them.

## What Are MCPs?

MCPs are **plugins that let AI agents talk to external services**. Instead of you manually copying files or navigating dashboards, the AI connects directly to:
- **Figma** → reads your designs, extracts components/tokens
- **Canva** → creates marketing assets, screenshots, icons
- **Firebase** → manages config, reads Firestore data, checks auth
- **GitHub** → creates branches, PRs, manages issues
- **Supabase** → manages database schemas, queries

## MCP Discovery Matrix

Based on your tech stack, recommend applicable MCPs:

| Service in Your Stack | Recommended MCP | What It Enables |
|:---------------------|:----------------|:----------------|
| **Figma** (design) | `figma-developer-mcp` | Read design files → generate component code with exact tokens |
| **Canva** (assets) | `canva-mcp-server` | Create App Store screenshots, icons, marketing graphics |
| **Firebase** | `firebase-mcp` | Manage Firestore, auth config, storage rules |
| **Supabase** | `supabase-mcp` | Manage schemas, run queries, handle auth |
| **GitHub** | `github-mcp` | Branches, PRs, issues, code review |
| **PostgreSQL** | `postgres-mcp` | Direct DB access, schema management |
| **Vercel** | `vercel-mcp` | Deploy, manage domains, check logs |
| **Stripe** | `stripe-mcp` | Payment setup, subscription management |
| **Sentry** | `sentry-mcp` | Error monitoring, crash reports |

## Setup Steps

### 1. Determine Which MCPs You Need
Ask yourself (or let the AI ask):
- What design tool am I using? → Figma/Canva MCP
- What backend/database? → Firebase/Supabase/Postgres MCP
- Where am I deploying? → Vercel/App Store MCP
- What do I need for assets? → Canva MCP

### 2. Install MCP Server

Most MCPs install via npm and run locally:
```bash
# Example: Figma MCP
npx -y figma-developer-mcp --figma-api-key=YOUR_KEY

# Example: Canva MCP
npx -y @anthropic/canva-mcp-server
```

### 3. Configure in Your IDE

#### For Gemini Code Assist / Antigravity
Add to your MCP configuration (settings may vary by IDE):
```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp"],
      "env": {
        "FIGMA_API_KEY": "your-figma-api-key"
      }
    }
  }
}
```

#### For Cursor
Add to `.cursor/mcp.json` in your project root.

#### For Claude Code
Add to `~/.claude/mcp_servers.json`.

### 4. Get API Keys

| Service | Where to Get Key |
|:--------|:----------------|
| Figma | Settings → Personal Access Tokens |
| Canva | Canva Developer Portal → Create App → Get API Key |
| Firebase | Firebase Console → Project Settings → Service Account |
| GitHub | Settings → Developer Settings → Personal Access Tokens |
| Vercel | Account Settings → Tokens |

### 5. Verify Connection
After setup, test by asking the AI:
- "List my Figma files" (Figma MCP)
- "Show my recent designs" (Canva MCP)
- "List my Firebase collections" (Firebase MCP)

## Rules
- Store API keys in environment variables, NOT in config files committed to git
- Only enable MCPs you actually need — each one uses resources
- Test MCP connections before relying on them in the build phase

## Verification
- [ ] Required MCPs identified based on tech stack
- [ ] API keys obtained for each
- [ ] MCP servers configured in IDE
- [ ] Test query successful for each connected MCP
