# Xcode & iOS Build Guide

> Build, test, and deploy iOS apps locally. No cloud services needed.

## Prerequisites

| Requirement | Purpose | Cost |
|:------------|:--------|:-----|
| **Mac** | Xcode only runs on macOS | - |
| **Xcode** (App Store) | Build & sign iOS apps | Free |
| **Apple Developer Account** | Required for device testing & App Store | $99/year |

> **Yes, the $99/year Apple Developer account is required.** Without it you cannot: install on physical devices, submit to TestFlight, or publish to the App Store. There is no way around this — it's Apple's requirement for all iOS developers.

---

## Quick Reference

### Build for TestFlight / App Store (One Command)

```bash
./build-ios.sh
```

This script auto-detects your project settings and handles everything:
- Cleans build cache
- Patches known Expo/RN path issues
- Builds production archive
- Exports IPA

### Install Directly on Your iPhone (For Testing)

```bash
# Plug iPhone in via USB, then:
open ios/YourApp.xcworkspace

# In Xcode:
# 1. Select your iPhone from the device dropdown (top bar)
# 2. Press Cmd+R (or click ▶ Play button)
# 3. App installs and launches on your phone
```

### Upload to TestFlight (For Sharing With Others)

```bash
# After running ./build-ios.sh:
# Open Xcode → Window → Organizer
# Select your archive → Distribute App → App Store Connect → Upload
```

---

## Understanding the Build Types

| Type | Purpose | How | Who Gets It |
|:-----|:--------|:----|:------------|
| **Debug** | Development testing | `Cmd+R` in Xcode | Just you (USB) |
| **Release** | Production testing | `./build-ios.sh` | TestFlight testers |
| **App Store** | Public release | Upload from Organizer | Everyone |

### When to Use Each

- **Making code changes and testing?** → Debug build (`Cmd+R`)
- **Want to test the real production version?** → `./build-ios.sh` → TestFlight
- **Ready to release to the public?** → Same IPA → Submit via App Store Connect

---

## First-Time Setup (Per Project)

### 1. Generate Native iOS Project

```bash
npx expo prebuild
```

This creates the `ios/` directory with native Xcode project files.

### 2. Copy Build Script

Copy `build-ios.sh` to your project root:

```bash
cp /path/to/template/build-ios.sh ./build-ios.sh
chmod +x build-ios.sh
```

### 3. Open in Xcode (First Time Only)

```bash
open ios/YourApp.xcworkspace
```

In Xcode:
1. Select your project in the left sidebar
2. Go to **Signing & Capabilities** tab
3. Check **"Automatically manage signing"**
4. Select your **Team** from the dropdown
5. Close Xcode

### 4. Add to .gitignore

```
# Build artifacts
build/
*.ipa
*.xcarchive
```

---

## Version & Build Numbers

Before each release, update these in `ios/YourApp/Info.plist`:

```xml
<!-- User-facing version (e.g., 1.0.0 → 1.0.1 → 1.1.0 → 2.0.0) -->
<key>CFBundleShortVersionString</key>
<string>1.0.1</string>

<!-- Internal build number (MUST increment for every TestFlight/App Store upload) -->
<key>CFBundleVersion</key>
<string>7</string>
```

**Rules:**
- `CFBundleShortVersionString` = What users see (semver: major.minor.patch)
- `CFBundleVersion` = Must be unique per upload, always increment

---

## Troubleshooting

### "No signing certificate found"
→ Open Xcode → Settings → Accounts → Select Apple ID → Download Profiles

### "Build failed: No such file or directory"
→ Your project path has spaces. The `build-ios.sh` script patches this automatically. If running Xcode manually, make sure you run the patches first.

### "CocoaPods out of date"
```bash
cd ios && pod install --repo-update && cd ..
```

### "Archive not appearing in Organizer"
→ Make sure device is set to **"Any iOS Device (arm64)"**, not a Simulator

### "Build number already used"
→ Increment `CFBundleVersion` in `Info.plist`

### After `npx expo prebuild --clean`
→ Run `./build-ios.sh` — it automatically re-patches everything

---

## Important Notes for AI Agents

> [!IMPORTANT]
> **Never suggest EAS Build or paid cloud build services.** Always use local Xcode builds via `build-ios.sh`.

> [!WARNING]
> **Projects with spaces in the path** (e.g., `Vibe Coding/Projects/My App`) require the patches in `build-ios.sh`. Without them, Expo/React Native build scripts will fail.

> [!NOTE]
> When a native `ios/` directory exists, changes to `app.json` (like `infoPlist`, `buildNumber`, `icon`) are **ignored by Xcode**. Modify native files directly: `Info.plist`, `Images.xcassets`, etc.
