# App Store Submission Checklist

> Step-by-step guide for submitting to iOS App Store and Google Play. Includes asset creation specs, common pitfalls, and the exact submission process.

## Pre-Submission: Asset Creation

### App Icon
| Spec | Requirement |
|:-----|:------------|
| **Size** | 1024×1024px |
| **Format** | PNG (no alpha/transparency) |
| **Corners** | Square — Apple rounds them automatically |
| **Content** | No text, recognizable at 29px, no photos |

**AI can help**: Generate icon concepts using image generation tools, then export at correct size.

### Screenshots (iOS)

Must provide screenshots for **at least** these device sizes:

| Device | Resolution | Required |
|:-------|:-----------|:---------|
| iPhone 6.7" (15 Pro Max) | 1290 × 2796px | ✅ Yes |
| iPhone 6.5" (11 Pro Max) | 1242 × 2688px | ✅ Yes |
| iPhone 5.5" (8 Plus) | 1242 × 2208px | Optional |
| iPad Pro 12.9" (6th gen) | 2048 × 2732px | If universal |

**Rules**:
- Minimum 3, maximum 10 per device size
- Show real app content (no placeholders)
- Can add marketing text overlays
- First screenshot = most important (shown in search)

**AI can help**: Take screenshots from simulator, add marketing overlays programmatically.

### Screenshots (Android)

| Spec | Requirement |
|:-----|:------------|
| Phone | Min 2 screenshots, 16:9 or 9:16 ratio |
| Tablet | Min 1 screenshot (if targeting tablets) |
| Feature Graphic | 1024×500px (required) |

---

## Submission Process: iOS (Step by Step)

### Step 1: Build
```bash
# Production build via EAS
eas build --profile production --platform ios
```
Wait for build to complete (~15-30 min). Download the `.ipa` if needed.

### Step 2: App Store Connect Setup
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - Platform: iOS
   - Name: [App Name] (30 chars max)
   - Primary Language
   - Bundle ID: must match `app.json` exactly
   - SKU: any unique string (e.g., `myapp-ios-v1`)

### Step 3: App Information
- [ ] **Category**: Choose primary + secondary (e.g., Education, Lifestyle)
- [ ] **Content Rights**: Declare if using third-party content
- [ ] **Age Rating**: Complete the questionnaire honestly

### Step 4: Pricing & Agreements
- [ ] Set price tier (Free or paid)
- [ ] **CRITICAL**: If offering paid features (subscriptions/IAP), you MUST sign the **Paid Applications Agreement** in Agreements, Tax, and Banking. This requires:
  - Bank account info
  - Tax forms (W-8BEN for non-US)
  - Contact info
  - This can take 1-3 days to process!

### Step 5: Prepare Version
- [ ] **Description**: 4000 char max. No special chars like `™` or `©` in some fields — test by pasting to plain text first
- [ ] **Keywords**: 100 char max, comma-separated. No spaces after commas.
- [ ] **What's New**: Brief changelog
- [ ] **Support URL**: Must be a live, accessible URL
- [ ] **Privacy Policy URL**: Must be a live, accessible URL
- [ ] Upload screenshots for each required device size
- [ ] Upload app icon (1024×1024)

### Step 6: App Privacy
1. Go to **App Privacy** section
2. For each data type you collect, declare:
   - What data (name, email, usage data, etc.)
   - Purpose (app functionality, analytics, etc.)
   - Whether linked to identity
   - Whether used for tracking

### Step 7: Submit Build
```bash
# Submit via EAS
eas submit --platform ios
```
Or upload manually via Transporter app.

### Step 8: Review Notes
- [ ] If login required: provide demo credentials
- [ ] Explain any non-obvious features
- [ ] Provide contact phone number + email
- [ ] Note any features requiring special hardware (camera, microphone)

### Step 9: Submit for Review
Click **Submit for Review**. Typical review: 24-48 hours.

---

## Submission Process: Android (Step by Step)

### Step 1: Build
```bash
eas build --profile production --platform android
```

### Step 2: Google Play Console
1. Go to [play.google.com/console](https://play.google.com/console)
2. **Create app** → fill basic info
3. Complete the **Dashboard setup checklist** (all items must be green)

### Step 3: Store Listing
- [ ] Title (50 chars), short description (80 chars), full description (4000 chars)
- [ ] Upload app icon (512×512), feature graphic (1024×500)
- [ ] Upload phone screenshots (min 2) + tablet (if applicable)

### Step 4: Content & Privacy
- [ ] Complete privacy policy
- [ ] Complete content rating (IARC)
- [ ] Data safety section
- [ ] Ads declaration
- [ ] Target audience

### Step 5: Release
- [ ] Upload `.aab` file
- [ ] Select release track (Internal → Closed → Open → Production)
- [ ] Submit for review (typically 1-7 days for first submission)

---

## Common Rejection Reasons & Fixes

| Reason | What Went Wrong | Fix |
|:-------|:----------------|:----|
| **Missing Delete Account** | Apple requires account deletion since 2022 | Build delete account in Settings BEFORE submission |
| **Invalid characters** | `™`, `©`, curly quotes, em dashes in metadata | Paste all text to plain text editor first, then re-paste |
| **Metadata refused** | Special characters in `promotionalText` or `description` fields crash the API | Use only basic ASCII in metadata |
| **Placeholder content** | Lorem ipsum, test data, "TODO" in the app | Search codebase for all placeholder strings |
| **Broken privacy policy** | URL returns 404 or is behind auth | Host on a public URL, test in incognito |
| **No demo account** | App requires login but no credentials provided | Create a persistent demo account, include in review notes |
| **Crash on launch** | Works in dev but not production build | Test clean install from production build on real device |
| **Paid Apps Agreement** | Not signed → app won't go live even after approval | Sign agreement + banking FIRST — takes days to process |
| **Bundle ID mismatch** | `app.json` says one ID, App Store Connect says another | Verify they match EXACTLY before building |
| **Screenshots wrong size** | Uploaded wrong resolution | Use exact pixel dimensions listed above |

---

## Post-Submission Timeline

| Stage | Duration | What Happens |
|:------|:---------|:-------------|
| **Upload** | Minutes | Build appears in App Store Connect |
| **Processing** | 10-30 min | Apple processes the binary |
| **In Review** | 24-48 hrs | Human reviewer tests the app |
| **Approved** → Live | Immediate or scheduled | You choose release date |
| **Rejected** | Variable | Fix issues → resubmit (back to review queue) |
