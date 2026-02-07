# Frontend Design System & Guidelines

> Every visual decision locked down. Fonts, colors, spacing, components. AI builds components exactly to this spec.

## 1. Design Principles

1. **Clarity** — Every element has a clear purpose
2. **Consistency** — Patterns repeat across the app
3. **Efficiency** — Minimize user effort
4. **Accessibility** — WCAG 2.1 Level AA compliance

---

## 2. Design Tokens

### Color Palette

#### Primary Colors
```css
--color-primary-50:  #[value];
--color-primary-100: #[value];
--color-primary-200: #[value];
--color-primary-300: #[value];
--color-primary-400: #[value];
--color-primary-500: #[value];  /* Main brand color */
--color-primary-600: #[value];
--color-primary-700: #[value];
--color-primary-800: #[value];
--color-primary-900: #[value];
```

#### Neutral Colors
```css
--color-neutral-50:  #[value];  /* Lightest background */
--color-neutral-100: #[value];
--color-neutral-200: #[value];  /* Borders */
--color-neutral-300: #[value];
--color-neutral-400: #[value];  /* Placeholder text */
--color-neutral-500: #[value];  /* Secondary text */
--color-neutral-600: #[value];
--color-neutral-700: #[value];  /* Primary text */
--color-neutral-800: #[value];
--color-neutral-900: #[value];  /* Headings */
```

#### Semantic Colors
```css
--color-success: #[value];  /* Confirmations */
--color-warning: #[value];  /* Cautions */
--color-error:   #[value];  /* Errors, destructive actions */
--color-info:    #[value];  /* Informational */
```

### Typography
```css
--font-sans: 'Inter', system-ui, sans-serif;
--font-mono: 'Fira Code', monospace;

--text-xs:   0.75rem;   /* 12px */
--text-sm:   0.875rem;  /* 14px */
--text-base: 1rem;      /* 16px */
--text-lg:   1.125rem;  /* 18px */
--text-xl:   1.25rem;   /* 20px */
--text-2xl:  1.5rem;    /* 24px */
--text-3xl:  1.875rem;  /* 30px */

--font-normal:   400;
--font-medium:   500;
--font-semibold: 600;
--font-bold:     700;
```

### Spacing Scale
```css
--spacing-1:  0.25rem;  /* 4px  */
--spacing-2:  0.5rem;   /* 8px  */
--spacing-3:  0.75rem;  /* 12px */
--spacing-4:  1rem;     /* 16px — default component padding */
--spacing-6:  1.5rem;   /* 24px */
--spacing-8:  2rem;     /* 32px — section spacing */
--spacing-12: 3rem;     /* 48px */
--spacing-16: 4rem;     /* 64px */
```

### Border Radius & Shadows
```css
--radius-sm:   0.125rem;  /* 2px  */
--radius-base: 0.25rem;   /* 4px  */
--radius-md:   0.375rem;  /* 6px  */
--radius-lg:   0.5rem;    /* 8px  */
--radius-xl:   0.75rem;   /* 12px */
--radius-full: 9999px;

--shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
--shadow-md: 0 4px 6px rgba(0,0,0,0.1);
--shadow-lg: 0 10px 15px rgba(0,0,0,0.1);
```

---

## 3. Component Specifications

### Buttons

| Variant | Use Case | Limit |
|:--------|:---------|:------|
| **Primary** | Main CTA | One per screen |
| **Secondary** | Supporting actions | As needed |
| **Danger** | Destructive actions | Always with confirmation |

**States**: Default → Hover → Active → Focus (2px ring) → Disabled (50% opacity) → Loading (spinner)

**Sizes**: Small (px-3 py-1.5) · Medium (px-4 py-2) · Large (px-6 py-3)

### Inputs
- Always pair with a `<label>`
- Show inline error messages below the field
- Disabled state: reduced opacity, `cursor-not-allowed`
- Focus state: primary color ring

### Cards
- Background: white / surface color
- Border: 1px neutral-200
- Padding: spacing-6
- Hover: elevated shadow transition (200ms)

### Modals
- Overlay: black/50% opacity
- Content: max-width 28rem, centered
- Actions: right-aligned (Cancel, Confirm)
- Close: click overlay or X button
- Focus trap required

---

## 4. Accessibility Checklist (WCAG 2.1 AA)

- [ ] Color contrast: 4.5:1 for normal text, 3:1 for large text
- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible (2px outline)
- [ ] Tab order logical
- [ ] Images have alt text
- [ ] Icon buttons have `aria-label`
- [ ] Form inputs have associated labels
- [ ] Error messages announced to screen readers
- [ ] Touch targets minimum 44×44px

---

## 5. Animation Guidelines

- Duration: 200ms default, 300ms max
- Easing: `ease-in-out` for most, `ease-out` for entrances
- Animate only `transform` and `opacity` for performance
- Respect `prefers-reduced-motion`

---

## 6. Responsive Breakpoints

```css
--breakpoint-sm: 640px;   /* Mobile */
--breakpoint-md: 768px;   /* Tablet */
--breakpoint-lg: 1024px;  /* Desktop */
--breakpoint-xl: 1280px;  /* Wide */
```

Mobile-first approach: base styles for mobile, progressive enhancement upward.

---

## AI Generation Prompt

```
Create a Frontend Design System document for [YOUR APP].

App Style: [Modern / Minimal / Bold / Professional]
Brand Colors: [Primary hex if known, or "suggest for a [type] app"]
Platform: [Web / React Native / Both]
UI Framework: [Tailwind / CSS-in-JS / StyleSheet / shadcn]

Generate:
1. DESIGN TOKENS: Complete color palette (primary 50-900, neutral 50-900, semantic), typography scale, spacing scale, radius, shadows — all with exact values
2. COMPONENT SPECS: For each component (Button, Input, Card, Modal, Alert), specify all variants, sizes, states, and usage rules
3. ACCESSIBILITY: WCAG 2.1 AA checklist for each component
4. ANIMATIONS: Duration, easing, and performance rules
5. RESPONSIVE: Breakpoints and mobile-first patterns

Provide exact CSS values — no approximations.
```
