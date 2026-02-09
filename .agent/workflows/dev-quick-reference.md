---
description: Quick reference for common development tasks
---

# Development Quick Reference

## Running the Development Server

### React Native/Expo Projects

```bash
# Start Metro bundler
npm start
# or
npx expo start
```

**When to keep it running:**
- ✅ **During active development** - for hot reload and fast refresh
- ✅ **When testing with Expo Go** - required for the app to connect
- ❌ **NOT needed for production builds** - `build-ios.sh` doesn't use it
- ❌ **NOT needed for TestFlight** - production IPA is self-contained

**You can safely close it when:**
- You're done coding for the day
- You're building for production (`./build-ios.sh`)
- You're testing via TestFlight

### Web Projects (Next.js/Vite)

```bash
# Development server
npm run dev

# Production build
npm run build
npm run start  # Preview production build
```

---

## Terminal Management

### Safe to Close

These terminals can be closed anytime:
- `npm start` / `npx expo start` (Metro bundler)
- `tail -f` log watchers
- Any completed build processes

### When to Restart

Restart Metro bundler (`npm start`) when:
- You install new dependencies
- You modify `app.json` or `babel.config.js`
- Hot reload stops working
- You see "Unable to resolve module" errors

---

## Common Commands

```bash
# Install dependencies
npm install

# Type checking
npm run type-check
# or
npx tsc --noEmit

# Linting
npm run lint

# Testing
npm test

# Clean cache (if things break)
npx expo start --clear

# Clean everything (nuclear option)
rm -rf node_modules package-lock.json
npm install
```

---

## Build vs Development

| Task | Metro Needed? | Command |
|:-----|:--------------|:--------|
| **Coding & testing** | ✅ Yes | `npm start` |
| **Production build** | ❌ No | `./build-ios.sh` |
| **TestFlight testing** | ❌ No | Install from TestFlight app |
| **Xcode direct install** | ❌ No | `Cmd+R` in Xcode |

---

## Quick Troubleshooting

### "Metro bundler not running"
```bash
npm start
```

### "Port 8081 already in use"
```bash
lsof -ti:8081 | xargs kill -9
npm start
```

### "Unable to resolve module"
```bash
npx expo start --clear
```

### "Build failed in Xcode"
```bash
# Clean and rebuild
rm -rf ios/build
./build-ios.sh
```
