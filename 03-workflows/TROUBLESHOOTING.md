# Troubleshooting Guide

> Common issues and their fixes, organized by category. Add to this document after every bug you solve.

## 🔥 Firebase

### "Component auth has not been registered yet"
**Cause**: Firebase modular SDK (v9/v10) has module registration issues in React Native, especially during HMR.  
**Fix**: Switch to Firebase Compat Layer (`firebase/compat/app`). This is a JS-only change — no native rebuild needed.
```typescript
import firebase from 'firebase/compat/app';
import 'firebase/compat/auth';
import 'firebase/compat/firestore';

if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
}
export const auth = firebase.auth();
export const db = firebase.firestore();
```

### "The given sign-in provider is disabled"
**Fix**: Enable the provider in Firebase Console → Authentication → Sign-in method.

### Session lost on force-close
**Cause**: Auth using in-memory persistence.  
**Fix**: Set persistence to LOCAL explicitly after initialization.

### "Cannot read property 'removeItem' of undefined"
**Cause**: AsyncStorage not linked for Firebase persistence.  
**Fix**: Ensure `@react-native-async-storage/async-storage` is installed and linked.

---

## 🔑 Authentication

### Social login fails silently
**Cause**: Lingering Firebase session prevents fresh OAuth credential processing.  
**Fix**: Call `signOut()` before any social provider `signIn()` call (clean slate strategy).

### Apple Sign-In — "Enum undefined" crash
**Cause**: Dynamic imports make enums like `AppleAuthenticationScope` undefined at runtime.  
**Fix**: Use numeric literals: `requestedScopes: [0, 1]` (0=FULL_NAME, 1=EMAIL).

### Google Sign-In — `idToken` not found
**Cause**: API change in recent versions wraps result in `data` property.  
**Fix**: `const { idToken } = (await GoogleSignin.signIn()).data;`

---

## 📱 Build & Simulator

### Xcode Error 65
**Cause**: Config mismatch, stale build artifacts, or corrupted Pods.  
**Fix**: 
1. Verify `bundleIdentifier` in `app.json` matches `GoogleService-Info.plist`
2. Run `npx expo prebuild --clean --platform ios`
3. Rebuild: `npx expo run:ios`

### "Port 8081 is running in another window"
**Cause**: Zombie node process blocking the port.  
**Fix**: `kill -9 <PID>` (from error message) or `npx kill-port 8081`

### "No development servers found" on phone
**Cause**: Expo server stopped or IP changed.  
**Fix**: Restart with `npx expo start --dev-client`. Ensure same Wi-Fi.

### Worklets/Reanimated crashes in simulator
**Fix**: 
1. `xcrun simctl uninstall booted host.exp.Exponent`
2. `npx expo start --ios`
3. If persists: `npx expo start -c`

---

## 🎨 UI Issues

### Context Provider errors ("must be used within XProvider")
**Causes** (in order of likelihood):
1. **Layout crash** — A dependency of `_layout.tsx` crashed silently, Expo Router skips the layout
2. **Multiple dev servers** — Kill all: `pkill -f node`, restart one
3. **Metro cache** — `npx expo start -c`
4. **Module duplication** — Delete `node_modules`, reinstall

### "Ghost" UI elements after removing a feature
**Cause**: Feature had UI in multiple layout modes (initial view, sticky header, inline).  
**Fix**: Search for icon names and feature hooks across the entire codebase.

---

## 🎙️ Audio

### "Sound is not loaded"
**Cause**: Calling control methods on unloaded/purged sound object.  
**Fix**: Always check `status.isLoaded` before calling `stopAsync`/`pauseAsync`. Use try-catch in timeouts.

### Speech Recognition always returns "denied"
**Cause**: `expo-speech-recognition` requires native capabilities — won't work in Expo Go.  
**Fix**: Test in Development Build on physical device.

---

## 🛠️ AI Tool Issues

### JSX attribute corruption (backslashes in quotes)
**Cause**: AI editing tools sometimes double-escape string attributes.  
**Symptom**: `mode=\\\"outlined\\\"` instead of `mode="outlined"`.  
**Fix**: Write a Python script for literal string replacement:
```python
with open('file.tsx', 'r') as f:
    lines = f.readlines()
lines[LINE_INDEX] = '    mode="outlined"\n'
with open('file.tsx', 'w') as f:
    f.writelines(lines)
```

---

## ➕ Add Your Issues Here

### [Issue Title]
**Symptom**:  
**Cause**:  
**Fix**:  
