---
description: Complete workflow for launching iOS apps to the App Store
---

# App Store Launch Workflow

> **For AI Agents:** When the user says "ready for production launch" or "deploy to App Store", follow this workflow exactly.

## Prerequisites Checklist

Before starting the launch process, verify:

- [ ] App is fully tested and stable
- [ ] All features work as expected
- [ ] No console errors or warnings in production build
- [ ] App icon is finalized (1024x1024 PNG)
- [ ] App Store metadata is ready (description, screenshots, keywords)
- [ ] Privacy policy URL is live (if collecting data)
- [ ] Apple Developer account is active ($99/year subscription)

---

## Phase 1: Pre-Launch Preparation

### 1.1 Version & Build Number

```bash
# Check current version in app.json
cat app.json | grep -A 2 "version"

# Increment version for new release:
# - Patch: 1.0.0 → 1.0.1 (bug fixes)
# - Minor: 1.0.0 → 1.1.0 (new features)
# - Major: 1.0.0 → 2.0.0 (breaking changes)
```

**Update in `app.json`:**
```json
{
  "expo": {
    "version": "1.0.1",
    "ios": {
      "buildNumber": "7"
    }
  }
}
```

**Critical:** Build number must be unique and increment with every upload.

### 1.2 Production Hardening

Run the production checklist:

```bash
# Remove all console.log statements
grep -r "console.log" src/

# Check for debug code
grep -r "__DEV__" src/

# Verify no test/mock data in production
grep -r "MOCK\|TEST\|FAKE" src/
```

### 1.3 Native Configuration Check

For React Native/Expo projects with native modifications:

```bash
# Verify Info.plist has required keys
cat ios/YourApp/Info.plist | grep -A 2 "UIBackgroundModes\|NSCameraUsageDescription"

# Verify app icon is set
ls -lh ios/YourApp/Images.xcassets/AppIcon.appiconset/
```

---

## Phase 2: Build Production IPA

### 2.1 Clean Build

```bash
# Clean previous builds
rm -rf build/
rm -rf ios/build/
rm -rf ~/Library/Developer/Xcode/DerivedData/YourApp-*

# For Expo projects, regenerate native code
npx expo prebuild --clean
```

### 2.2 Run Build Script

// turbo
```bash
# Execute the build script
./build-ios.sh
```

**Expected output:**
- Archive created: `build/YourApp.xcarchive`
- IPA exported: `build/YourApp.ipa`
- File size: ~15-50 MB (typical)

### 2.3 Validate IPA

```bash
# Check IPA was created
ls -lh build/*.ipa

# Verify it's not corrupted
file build/YourApp.ipa
# Should output: "Zip archive data"
```

---

## Phase 3: Upload to App Store Connect

### 3.1 Upload via Transporter

1. **Open Transporter** (Mac App Store app)
2. **Sign in** with Apple ID
3. **Drag & drop** `build/YourApp.ipa`
4. **Click "Deliver"**
5. **Wait** for upload to complete (~2-5 minutes)

### 3.2 Wait for Processing

- **Time:** 5-15 minutes
- **Email notification:** "Your build has been processed"
- **Check status:** App Store Connect → TestFlight → iOS Builds

---

## Phase 4: TestFlight Testing

### 4.1 Internal Testing

Once build is processed:

1. **App Store Connect** → **TestFlight** → **iOS Builds**
2. Select the new build
3. **Add to Internal Testing** group
4. **Install via TestFlight** on your iPhone
5. **Test thoroughly:**
   - All critical user flows
   - Background features (audio, notifications)
   - Offline functionality
   - Payment flows (if applicable)

### 4.2 External Testing (Optional)

For beta testers:

1. **Create External Testing group**
2. **Add testers** (email addresses)
3. **Submit for Beta Review** (1-2 days)
4. **Testers receive email** with TestFlight link

---

## Phase 5: App Store Submission

### 5.1 Prepare App Store Listing

In **App Store Connect** → **Your App** → **App Store** tab:

**Required:**
- [ ] App Name (30 chars max)
- [ ] Subtitle (30 chars max)
- [ ] Description (4000 chars max)
- [ ] Keywords (100 chars, comma-separated)
- [ ] Screenshots (6.7", 6.5", 5.5" required)
- [ ] App Icon (1024x1024)
- [ ] Privacy Policy URL
- [ ] Category (Primary & Secondary)
- [ ] Age Rating

**Optional but recommended:**
- [ ] Promotional Text (170 chars)
- [ ] App Preview videos
- [ ] What's New (for updates)

### 5.2 Select Build

1. **App Store Connect** → **Your App** → **App Store** tab
2. **Build** section → **Select a build before you submit your app**
3. **Choose** the build you just uploaded
4. **Export Compliance:** Answer questions about encryption

### 5.3 Submit for Review

1. **Review all sections** (green checkmarks required)
2. **Add to Review** button appears
3. **Submit for Review**
4. **Wait** for Apple review (1-3 days typically)

---

## Phase 6: Post-Submission

### 6.1 Monitor Review Status

**App Store Connect** → **Your App** → **App Store** tab

**Statuses:**
- **Waiting for Review:** In queue
- **In Review:** Apple is reviewing (usually 24-48 hours)
- **Pending Developer Release:** Approved! (you control release)
- **Ready for Sale:** Live on App Store
- **Rejected:** See rejection reasons, fix, resubmit

### 6.2 If Rejected

1. **Read rejection message** carefully
2. **Fix the issues** in your code
3. **Increment build number** in `app.json`
4. **Rebuild:** `./build-ios.sh`
5. **Upload new build** via Transporter
6. **Resubmit** with resolution notes

### 6.3 If Approved

**Manual Release:**
1. **Release this version** button appears
2. **Click to publish** to App Store
3. **Live within 24 hours**

**Automatic Release:**
- Set in **App Version Information** → **Automatically release this version**
- Goes live immediately upon approval

---

## Phase 7: Post-Launch

### 7.1 Monitor

- **App Store Connect** → **Analytics**
- **Crash reports** (Xcode Organizer)
- **User reviews** (respond within 7 days)
- **Download metrics**

### 7.2 Updates

For future updates:

1. **Make code changes**
2. **Increment version/build** in `app.json`
3. **Run** `./build-ios.sh`
4. **Upload** via Transporter
5. **Test** on TestFlight
6. **Submit** update to App Store

---

## Quick Reference Commands

```bash
# Full deployment pipeline
npx expo prebuild --clean  # If using Expo with native mods
./build-ios.sh             # Build IPA
# Upload via Transporter GUI
# Test via TestFlight
# Submit via App Store Connect web
```

---

## Common Issues & Solutions

### "Build number already used"
→ Increment `buildNumber` in `app.json` or `ios/YourApp/Info.plist`

### "Missing compliance"
→ Answer export compliance questions in App Store Connect

### "Invalid binary"
→ Check Xcode build logs, ensure all required frameworks are included

### "Metadata rejected"
→ Review App Store Review Guidelines, update screenshots/description

### "Guideline 2.1 - Performance - App Completeness"
→ Ensure app is fully functional, no placeholder content, all features work

---

## For AI Agents: Automation Checklist

When user says "ready for production launch":

1. ✅ Verify `app.json` version and build number are incremented
2. ✅ Run production hardening checks (no console.logs, debug code)
3. ✅ Execute `./build-ios.sh`
4. ✅ Verify IPA was created successfully
5. ✅ Instruct user to upload via Transporter
6. ✅ Remind user to test on TestFlight before submission
7. ✅ Provide App Store submission checklist
8. ✅ Offer to help with metadata preparation

**Never:**
- ❌ Skip version/build number increment
- ❌ Submit without TestFlight testing
- ❌ Leave debug code in production
- ❌ Suggest EAS Build or paid cloud services
