# Frontend Design System & Guidelines

> Every visual decision locked down. Fonts, colors, spacing, components. AI builds components exactly to this spec.

## 1. Design Principles

1. **Premium Dark** — A sleek, modern dark theme that feels like a pro tool
2. **Glanceable** — Users can triage leads in seconds, not minutes
3. **Tactile** — Swipe gestures, haptic feedback, satisfying micro-animations
4. **Accessible** — WCAG 2.1 AA for all interactive elements

---

## 2. Design Tokens

### Color Palette (Dark Mode)

#### Primary Colors — Electric Purple
```swift
Color.primary50:  Color(hex: "#F5F3FF")  // Text on dark
Color.primary100: Color(hex: "#EDE9FE")
Color.primary200: Color(hex: "#DDD6FE")
Color.primary300: Color(hex: "#C4B5FD")
Color.primary400: Color(hex: "#A78BFA")
Color.primary500: Color(hex: "#8B5CF6")  // ★ Main brand color
Color.primary600: Color(hex: "#7C3AED")  // CTA buttons
Color.primary700: Color(hex: "#6D28D9")
Color.primary800: Color(hex: "#5B21B6")
Color.primary900: Color(hex: "#4C1D95")
```

#### Background Colors — Deep Space
```swift
Color.bg900:      Color(hex: "#06060B")  // Deepest background
Color.bg800:      Color(hex: "#0A0A12")  // Screen background ★
Color.bg700:      Color(hex: "#111119")  // Card background
Color.bg600:      Color(hex: "#1A1A24")  // Elevated card / sheet
Color.bg500:      Color(hex: "#252530")  // Input background
Color.bgGlass:    Color.white.opacity(0.06)  // Glassmorphic overlay
```

#### Accent Colors
```swift
Color.accentCyan:    Color(hex: "#06B6D4")  // Secondary actions
Color.accentBlue:    Color(hex: "#3B82F6")  // Links, info
```

#### Semantic Colors
```swift
Color.scoreHigh:     Color(hex: "#10B981")  // Score ≥80 (Emerald)
Color.scoreMedium:   Color(hex: "#F59E0B")  // Score 50-79 (Amber)
Color.scoreLow:      Color(hex: "#6B7280")  // Score <50 (Gray)

Color.success:       Color(hex: "#10B981")  // Confirmations
Color.warning:       Color(hex: "#F59E0B")  // Cautions
Color.error:         Color(hex: "#EF4444")  // Errors, destructive
Color.info:          Color(hex: "#3B82F6")  // Informational
```

#### Text Colors
```swift
Color.textPrimary:   Color.white.opacity(0.92)   // Headings, important text
Color.textSecondary: Color.white.opacity(0.64)   // Body, descriptions
Color.textTertiary:  Color.white.opacity(0.40)   // Placeholders, timestamps
Color.textInverse:   Color(hex: "#06060B")        // Text on light backgrounds
```

### Typography (San Francisco + Custom)

```swift
// Primary: SF Pro (system default on iOS — no import needed)
// Accent: Poppins (for headings — via Google Fonts)

Font.heading1:    .custom("Poppins-Bold", size: 28)      // Screen titles
Font.heading2:    .custom("Poppins-SemiBold", size: 22)   // Section headers
Font.heading3:    .custom("Poppins-SemiBold", size: 18)   // Card titles
Font.bodyLarge:   .system(size: 16, weight: .regular)     // Main body
Font.bodyMedium:  .system(size: 14, weight: .regular)     // Secondary body
Font.bodySmall:   .system(size: 12, weight: .regular)     // Captions
Font.scoreBadge:  .system(size: 14, weight: .bold, design: .rounded)  // Score numbers
Font.mono:        .system(size: 12, design: .monospaced)  // Data/metrics
```

### Spacing Scale
```swift
CGFloat.spacing1:   4   // Tight internal spacing
CGFloat.spacing2:   8   // Between related elements
CGFloat.spacing3:  12   // Component internal padding
CGFloat.spacing4:  16   // Default padding ★
CGFloat.spacing5:  20   // Card content padding
CGFloat.spacing6:  24   // Section spacing
CGFloat.spacing8:  32   // Screen edges
CGFloat.spacing12: 48   // Major section breaks
```

### Border Radius & Shadows
```swift
CGFloat.radiusSm:    8   // Buttons, chips
CGFloat.radiusMd:   12   // Cards, inputs
CGFloat.radiusLg:   16   // Modal sheets
CGFloat.radiusXl:   20   // Bottom sheets
CGFloat.radiusFull: 999  // Circular elements (avatars, dots)

// Card shadow (glassmorphic)
.shadow(color: Color.primary500.opacity(0.08), radius: 16, x: 0, y: 4)
.shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
```

---

## 3. Component Specifications

### Buttons

| Variant | Use Case | Appearance |
|:--------|:---------|:-----------|
| **Primary** | Main CTA ("Get Started", "Subscribe") | Filled purple gradient, white text |
| **Secondary** | Supporting ("Copy Reply", "Filter") | Bordered, purple text |
| **Ghost** | Tertiary ("Skip", "Not now") | No border, muted text |
| **Danger** | Destructive ("Delete", "Sign Out") | Red background |
| **Icon** | Actions (save, dismiss, filter) | Circular, translucent bg |

**States**: Default → Pressed (scale 0.96, opacity 0.8) → Disabled (50% opacity)
**Sizes**: Small (h: 36) · Medium (h: 44) · Large (h: 52)
**Haptic**: Light impact on press

### Lead Cards
- Background: `bg700` with subtle gradient border based on score
- Corner radius: `radiusMd` (12)
- Padding: `spacing5` (20)
- Score badge: top-right, circular, colored by score tier
- Swipe right indicator: green "Save" with checkmark
- Swipe left indicator: red "Dismiss" with X
- Enter animation: fade + slide up (0.3s spring)
- Haptic: medium impact on swipe completion

### Inputs
- Background: `bg500`
- Border: 1px `white.opacity(0.1)`; focus: `primary500`
- Corner radius: `radiusSm` (8)
- Height: 48pt
- Floating label on focus
- Error state: red border + message below

### Chips / Tags
- Used for: keyword tags, subreddit names, platform badges
- Background: `bgGlass` with border
- Corner radius: `radiusFull` (pill shape)
- Deletable: trailing X icon

### Glassmorphic Sheets
- Background: `bg600` with `0.85` opacity
- Blur: `ultraThinMaterial`
- Corner radius: `radiusXl` (20) top corners
- Drag indicator: capsule at top

---

## 4. Gradient Definitions

```swift
// Primary gradient (CTA buttons, hero elements)
LinearGradient(
    colors: [Color(hex: "#8B5CF6"), Color(hex: "#3B82F6")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// Score gradient (high-score card borders)
LinearGradient(
    colors: [Color(hex: "#10B981"), Color(hex: "#06B6D4")],
    startPoint: .leading,
    endPoint: .trailing
)

// Background gradient (screen backgrounds)
LinearGradient(
    colors: [Color(hex: "#0A0A12"), Color(hex: "#0D0D1A")],
    startPoint: .top,
    endPoint: .bottom
)
```

---

## 5. Accessibility Checklist (WCAG 2.1 AA)

- [ ] Color contrast: 4.5:1 for text on dark backgrounds (verified for all tokens)
- [ ] All interactive elements: min 44×44pt touch targets
- [ ] VoiceOver labels for all buttons and cards
- [ ] Score communicated as text, not just color
- [ ] Dynamic Type support for all text styles
- [ ] Swipe actions have tap alternatives (action buttons on detail)
- [ ] Reduced Motion: disable card animations when enabled

---

## 6. Animation Guidelines

| Animation | Duration | Easing | Element |
|:----------|:---------|:-------|:--------|
| Card entrance | 0.4s | Spring (response: 0.5, damping: 0.7) | Lead cards |
| Button press | 0.15s | EaseOut | Scale to 0.96 |
| Tab switch | 0.25s | EaseInOut | Cross-fade content |
| Sheet present | 0.3s | Spring (response: 0.4, damping: 0.85) | Bottom sheets |
| Score counter | 0.8s | EaseOut | Number counting up |
| Swipe action | 0.3s | Spring | Card slide + fade |
| Pull refresh | System | System | Spinner |

### Rules
- Respect `UIAccessibility.isReduceMotionEnabled`
- Never block interaction for animation
- Haptic feedback: light (buttons), medium (swipes), heavy (destructive)
