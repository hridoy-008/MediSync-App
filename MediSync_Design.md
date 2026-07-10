# MediSync — Design Description & UX Specification

**Version:** 1.0 (Draft)
**Owner:** Masum
**Status:** For review
**Companion to:** MediSync_PRD.md, MediSync_TRD.md
**Last updated:** 23 June 2026

> This document defines MediSync's design philosophy, visual identity, design tokens, key screens, component library, and accessibility/localization rules. It is written so the design system is **tokenized and reusable** (white-label-ready) and translates cleanly into the Flutter design-system module.

---

## 1. Design Principles

1. **Calm, clinical-but-warm.** Health apps must feel trustworthy and reassuring, not sterile or alarming. Generous whitespace, soft surfaces, a confident accent — credible without being cold.
2. **Glanceable.** The "Today" view answers one question instantly: *what do I need to do next?* Reminders, doses, meals — readable at arm's length.
3. **Confirm, never assume.** Every extracted medical fact is presented for review with clear visual honesty about confidence. The UI never pretends OCR is certain.
4. **Accessible by default.** Designed for a 62-year-old in Bangla and a 27-year-old in English alike: large type, high contrast, big tap targets, no reliance on color alone.
5. **Bilingual as a first-class citizen.** Bangla is not an afterthought translation — layouts, line-heights, and components are built to hold Bangla typography gracefully.
6. **Tokenized & reusable.** Every visual decision is a token, so the whole app can be re-skinned for another product by swapping a theme file.

---

## 2. Brand & Visual Identity

**Personality:** trustworthy, modern, caring, clear.

**Logo concept:** a stylized "sync" motion (two arcs / a pulse loop) merged with a soft health cross or heartbeat line — communicating "your health, kept in sync." Works in mono for app icon and splash.

**Imagery & illustration:** simple, friendly line-illustrations for empty states and onboarding (a person taking medicine, a glass of water, sleeping). Avoid stock-photo clutter; avoid anything anxiety-inducing.

---

## 3. Design Tokens

### 3.1 Color

A teal/green primary (health, calm, growth) with a warm secondary and clear semantic colors. Defined as tokens; light theme primary, dark theme supported.

| Token | Light | Role |
|---|---|---|
| `primary` | `#1C9B8E` (calm teal) | Primary actions, brand |
| `primaryContainer` | `#D5F2EE` | Tinted surfaces, selected states |
| `secondary` | `#F2A33C` (warm amber) | Highlights, meal/energy accents |
| `background` | `#F7FAF9` | App background |
| `surface` | `#FFFFFF` | Cards, sheets |
| `surfaceVariant` | `#EEF3F2` | Subtle dividers/fills |
| `onSurface` | `#1A2422` | Primary text |
| `onSurfaceMuted` | `#5C6B68` | Secondary text |
| `success` | `#2E9E5B` | "Taken", on-track |
| `warning` | `#E2A100` | Low-confidence flags, snooze |
| `danger` | `#D9534F` | Missed dose, destructive |
| `info` | `#3B82C4` | Tips, neutral info |

**Semantic mapping for reminders:** medicine = `primary`, meal = `secondary`/amber, water = `info`/blue, sleep = an indigo accent — so each domain is recognizable at a glance. Never rely on color alone; pair with icon + label.

### 3.2 Typography

- **English:** a clean, highly legible sans (e.g. Inter / system).
- **Bangla:** a bundled, well-hinted Bangla font (Noto Bengali or equivalent) for correct conjuncts; **slightly larger line-height** than English to avoid clipping.

| Token | Size / weight | Use |
|---|---|---|
| `displayLarge` | 28 / 700 | Screen titles |
| `headline` | 22 / 600 | Section headers |
| `titleMedium` | 18 / 600 | Card titles, med names |
| `body` | 16 / 400 | Default body |
| `bodyMuted` | 14 / 400 | Secondary info |
| `caption` | 12 / 500 | Timestamps, labels |

Base body never below 14; reminder-critical text ≥ 16. Support OS text-scaling.

### 3.3 Spacing, radius, elevation

- **Spacing scale (4-pt):** 4, 8, 12, 16, 24, 32, 48.
- **Radius:** `sm` 8, `md` 12, `lg` 16, `pill` 999. Cards use `md`–`lg` for a soft, modern feel.
- **Elevation:** soft, low shadows (`y2 blur8 12% opacity`); avoid harsh drop shadows. Dark theme uses surface-tint instead of heavy shadow.
- **Tap targets:** minimum 48×48 dp.

### 3.4 Iconography

Consistent rounded line-icon set. Each reminder type has a fixed icon (pill, plate, water drop, moon) used everywhere for instant recognition.

---

## 4. Information Architecture

```
Bottom navigation (4 tabs):
  ① Home / Today      ② Prescriptions      ③ Plan (BMI/Diet/Exercise)      ④ Profile

Global:
  • FAB "＋ Add prescription" on Home
  • Language toggle (Profile + onboarding)
```

---

## 5. Key Screens & Flows

### 5.1 Onboarding
- 3 light slides (capture → remind → stay healthy), then **language choice (Bangla/English)** and core permission priming (notifications, exact alarm, camera) explained in plain language *before* the OS prompts.

### 5.2 Home / Today (the heart of the app)
- **Top:** greeting + today's date; quick adherence ring ("4 of 6 done").
- **Timeline:** chronological list of today's events — each card shows icon (type), name, time, and an inline **Taken / Snooze / Skip** control. Color + icon encode type and status.
- **Next-up** item is visually emphasized.
- Empty state (no prescriptions): friendly illustration + "Add your first prescription."

### 5.3 Prescription capture → review (the trust-critical flow)
1. **Capture:** camera or gallery; crop/rotate/enhance with guides.
2. **Processing:** clear, calm progress state ("Reading your prescription…"); honest about cloud step if used.
3. **Review & Edit (critical):**
   - Sections: **Medicines**, **Tests**, **Instructions**.
   - Each medicine = editable card: name, dose, frequency, before/after food, duration.
   - **Low-confidence fields are visually flagged** (amber underline + "Please verify" tag) — the user's eye is drawn to exactly what to check.
   - Prominent disclaimer banner: *"Please verify all details. Not a substitute for medical advice."*
   - Primary button **"Confirm & set reminders"** is the only path to scheduling.
4. **Schedule preview:** shows the reminders about to be created; user can tweak times (e.g., align to meals) before finalizing.

### 5.4 Reminders & settings
- **Medicine schedule** view: per-medicine times, editable.
- **Meal times:** simple time pickers for each meal; toggle which meals are active.
- **Water:** start/end window, interval, daily target — a clean stepper, not a complex form.
- **Sleep:** bedtime + wake time + optional wind-down reminder.
- Design bias (per your preference): **minimal, clean controls over complex selection mechanics** — sensible defaults, few taps.

### 5.5 BMI → Plan
- **Input:** height, weight, age, sex, activity level (segmented control).
- **Result:** BMI value + category shown on a clear gauge (underweight / normal / overweight / obese), color-coded.
- **Diet chart:** localized daily meal suggestions in a readable card layout.
- **Exercise plan:** simple list with durations/icons.
- Persistent disclaimer footer.

### 5.6 Profile
- User info, language toggle, notification/permission status with fix-it guidance, theme (light/dark), data & privacy controls, (P2-reserved) medical ID.

### 5.7 Notification UX
- Rich notification with type icon, medicine/meal name, time, and **action buttons** (Taken / Snooze / Skip).
- Medicine reminders use a high-importance channel; optionally a full-screen alarm style for critical doses.
- **Missed-dose follow-up** notification is gentle, not scolding ("You haven't confirmed your 2 PM dose — tap to update").

---

## 6. Component Library (design-system module)

Reusable, tokenized components mapped 1:1 to the Flutter `core/design_system`:

- **Buttons:** primary, secondary, text, destructive; loading + disabled states.
- **ReminderCard:** icon slot, title, subtitle/time, trailing action; status variants (pending/taken/missed/snoozed).
- **EditableFieldCard:** label, value, confidence flag, edit affordance (used in review).
- **Inputs:** text field, time picker, segmented control, stepper, dropdown — all with Bangla-safe sizing.
- **Banner / Disclaimer:** info/warning/danger variants.
- **AdherenceRing & BMIGauge:** data-viz primitives.
- **EmptyState, LoadingState, ErrorState:** consistent across features.
- **BottomSheet, Dialog, Snackbar:** standardized.

Every component reads from tokens — no hardcoded colors/sizes — so a theme swap re-skins the entire app.

---

## 7. States, Motion & Feedback

- **Every screen defines** loading, empty, error, and success states explicitly.
- **Motion:** subtle and purposeful — 150–250 ms ease transitions, a satisfying check animation on "Taken," gentle progress for OCR. No gratuitous animation.
- **Haptics:** light tap feedback on confirm actions.
- **Honest feedback:** processing states never imply certainty; errors offer a clear recovery path (retry, manual entry).

---

## 8. Accessibility & Localization

- **Contrast:** text meets WCAG AA against its surface; status never conveyed by color alone (icon + label always).
- **Text scaling:** layouts tolerate OS large-text settings without clipping; Bangla gets extra line-height.
- **Tap targets:** ≥ 48 dp; key actions reachable one-handed.
- **Bangla rendering:** verified across components; numerals (০-৯ / 0-9) display correctly per locale; dates/times localized.
- **Screen readers:** semantic labels on all interactive elements, including notification actions.
- **Elderly-friendly mode (consideration):** an optional larger-type, simplified Today view.

---

## 9. Dark Theme

Full dark variant via token remapping: deep neutral surfaces, tint-based elevation, preserved semantic colors with adjusted contrast. No separate component work — only token values change, reinforcing the reusable system.

---

## 10. Design-to-Code Handoff Notes

- Tokens → `core/design_system/tokens.dart` (colors, type, spacing, radius, elevation).
- Theme → Material 3 `ThemeData` light/dark built from tokens.
- Components → stateless, token-driven widgets in `core/design_system/components/`.
- Bangla font bundled in assets and registered as the app's text theme fallback.
- White-label: a single theme/config file swap re-skins the product end-to-end.
