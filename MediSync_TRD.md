# MediSync — Technical Requirements Document (TRD)

**Version:** 1.0 (Draft)
**Owner:** Masum
**Status:** For review
**Companion to:** MediSync_PRD.md
**Last updated:** 23 June 2026

> This document specifies the technical architecture, stack, modules, data model, and the hard engineering problems (offline alarms, bilingual OCR) behind MediSync. All choices favor **modularity and reuse** so the codebase can be re-skinned for other health products.

---

## 1. Architecture Overview

MediSync is an **offline-first Flutter + Firebase app**. Firebase provides the cloud data store (Cloud Firestore), authentication, serverless OCR processing (Cloud Functions), image storage, and push (FCM). Firestore runs with **offline persistence enabled**, so the app stays fully functional without connectivity and syncs automatically when back online.

**Critical reliability note:** the OS-level alarm/reminder scheduler does **not** depend on the Firebase SDK being initialized. The materialized reminder schedule is mirrored into a tiny local store (Hive/Drift) that the alarm scheduler and the boot receiver read directly. This guarantees reminders fire offline and survive reboot even before Firebase initializes. Firestore remains the system of record and sync layer; the local mirror exists purely to make the alarm engine bullet-proof. *(This is a recommended design — see §6; flag if you'd prefer to rely solely on Firestore's offline cache.)*

```
┌───────────────────────────────────────────────────────────────┐
│                        Flutter App (Client)                    │
│                                                                │
│  Presentation (GetX)  →  Domain (use-cases)  →  Data (repos)   │
│                                                                │
│  Core services:  Notification/Alarm · OCR · Data · i18n ·     │
│                  DesignSystem · Permissions                    │
│                                                                │
│  Local mirror (Hive/Drift): materialized reminder schedule    │
│  → read by OS alarm scheduler + boot receiver (Firebase-free) │
└───────────────┬───────────────────────────────┬───────────────┘
                │ (offline: fully functional)    │ (online: auto-sync)
                ▼                                 ▼
        OS Alarm/Notification            Firebase
        scheduler                        ├─ Cloud Firestore (offline persistence)
                                         ├─ Firebase Auth
                                         ├─ Firebase Storage (Rx images)
                                         ├─ Cloud Functions (OCR + LLM proxy)
                                         ├─ Cloud Messaging (FCM)
                                         └─ (future) drug DB, reports
                                                  │
                                                  ▼
                                   Cloud Vision + LLM structuring
                                   (called from Cloud Functions)
```

### Architectural principles
- **Feature-first clean architecture.** Each feature is a self-contained module (`data` / `domain` / `presentation`); cross-cutting concerns live in `core`.
- **Dependency inversion.** Features depend on abstract interfaces (e.g. `OcrService`, `ReminderScheduler`), not concrete vendors — so ML Kit, Cloud Vision, or an LLM can be swapped without touching feature code.
- **Offline-first.** Every core flow works with zero connectivity. Network is an enhancement layer behind interfaces.
- **Config-driven / white-label-ready.** Branding, feature toggles, and locale come from a central config so the app can be re-themed and re-shipped.

---

## 2. Technology Stack

| Layer | Choice | Notes |
|---|---|---|
| App framework | **Flutter (Android + iOS)** | Single codebase |
| Language | Dart (null-safe) | |
| State management | **GetX** | Controllers + reactive `Obx`; follow strict Obx rules (read all observables unconditionally before conditionals) |
| Local data layer | **Cloud Firestore (offline persistence ON)** | Primary store + auto-sync; cached on-device for offline use |
| Local reminder mirror | **Hive** (or Drift) | Tiny materialized schedule for the alarm engine / boot receiver — Firebase-independent |
| Lightweight prefs | Hive / shared_preferences | Settings, flags |
| Notifications | **flutter_local_notifications** | Scheduling, channels, actions |
| Exact alarms | **android_alarm_manager_plus** / native `AlarmManager` (Android) | For reboot-surviving, exact-time triggers |
| On-device OCR | **google_mlkit_text_recognition** | Fast English/Latin path, offline |
| Cloud OCR | **Google Cloud Vision** (called from Cloud Functions) | Bengali printed text support |
| Structuring | **LLM (in Cloud Functions)** | Raw text → structured medicines/tests/instructions JSON |
| i18n | Flutter `intl` + ARB files | Bangla/English; Bangla-capable font bundled |
| Image handling | image_picker, image_cropper | Capture, crop, rotate, enhance |
| Charts (P1) | fl_chart | Vitals/adherence trends |
| Backend | **Firebase (serverless)** | Firestore, Auth, Cloud Functions, Storage, FCM — no self-managed server |
| Auth | **Firebase Auth** | Email/phone/Google sign-in |
| Cloud storage | **Firebase Storage** | Prescription images (with explicit consent) |
| Serverless compute | **Cloud Functions** | OCR proxy, LLM structuring, secure key handling |
| Push | **Firebase Cloud Messaging** | Sync/caregiver nudges only — **not** the primary reminder path |

---

## 3. Module Breakdown

```
lib/
├── core/
│   ├── design_system/        # tokens, theme, components (see Design doc)
│   ├── notifications/        # ReminderScheduler abstraction + impls
│   ├── ocr/                  # OcrService abstraction + ML Kit / cloud impls
│   ├── data/                 # Firestore repositories + local mirror (Hive/Drift)
│   ├── firebase/             # Firebase init, Auth, Firestore, Storage, Functions wrappers
│   ├── localization/         # i18n, locale controller, Bangla fonts
│   ├── permissions/          # notification, exact-alarm, battery, camera
│   ├── config/               # white-label/app config, feature flags
│   └── utils/                # result types, extensions, logging
│
├── features/
│   ├── prescription/         # capture, extract, review/edit, history
│   ├── reminders/            # medicine/meal/water/sleep schedules + logs
│   ├── meal/                 # meal-time config
│   ├── hydration_sleep/      # water & sleep settings
│   ├── bmi_plan/             # BMI calc + diet/exercise plan
│   ├── profile/              # user profile, medical ID (P2-ready)
│   └── dashboard/            # home, today view, adherence summary
│
└── main.dart
```

Each feature exposes a clean API to the dashboard; features never import each other directly — they coordinate through `core` services and shared domain models.

---

## 4. Data Model (core entities)

| Entity | Key fields | Notes |
|---|---|---|
| **UserProfile** | id, name, locale, height, weight, age, sex, activityLevel, bmi, bmiCategory | BMI cached; medical-ID fields reserved (P2) |
| **Prescription** | id, imagePath, capturedAt, rawText, locale, source(camera/gallery), reviewed(bool) | Stores original image + raw OCR |
| **Medicine** | id, prescriptionId, name, dose, frequency, timing(before/after/with food), durationDays, notes, confidenceFlags | From extraction; user-editable |
| **TestItem** | id, prescriptionId, name, instructions, confidenceFlags | Detected tests |
| **Instruction** | id, prescriptionId, text | Free-text guidance |
| **Reminder** | id, type(medicine/meal/water/sleep), refId, scheduledTime, recurrenceRule, channel, status, graceWindow | The schedulable unit |
| **ReminderLog** | id, reminderId, firedAt, action(taken/skipped/snoozed/missed), confirmedAt | Adherence source data |
| **MealConfig** | id, mealType(breakfast/lunch/dinner/...), time, enabled | Drives meal + food-relative meds |
| **HydrationConfig** | startTime, endTime, intervalMins, dailyTargetMl | Water reminders |
| **SleepConfig** | bedtime, wakeTime, windDownMins | Sleep reminders |
| **DietPlan / ExercisePlan** | id, bmiCategory, items[], locale | Generated, localized |

**Recurrence** is stored as an RRULE-like rule so schedules regenerate deterministically on-device — critical for offline and reboot recovery.

**Firestore mapping:** entities live under a per-user document tree (e.g. `users/{uid}/prescriptions/{id}`, `.../reminders/{id}`, `.../logs/{id}`) so Security Rules can scope all access to the authenticated owner. Firestore offline persistence caches these on-device automatically. The **Reminder** rows (and only those) are additionally materialized into the local Hive/Drift mirror that the alarm scheduler and boot receiver read — keeping reminder firing independent of Firebase SDK state.

---

## 5. Prescription Extraction Pipeline

The riskiest accuracy surface. Designed as a **routed, confidence-aware pipeline with a mandatory human gate.**

```
Image → preprocess (deskew, contrast, crop)
      → language/script detection
      → OCR routing:
            • English/Latin  → on-device ML Kit (fast, offline)
            • Bangla / mixed → Cloud Vision (via Cloud Functions)  [needs network]
      → raw text
      → LLM structuring (Cloud Functions): text → {medicines[], tests[], instructions[]}
        with per-field confidence
      → REVIEW & EDIT SCREEN  ← mandatory user confirmation, low-confidence fields flagged
      → persist confirmed data → generate reminders
```

### Engineering rules
- **No scheduling before confirmation** (enforced in domain layer, not just UI).
- **Confidence flags** propagate from OCR/LLM to the review UI; uncertain fields are visually distinct.
- **Offline fallback:** if only on-device OCR is available (no network), the app still extracts English text and lets the user manually fill Bangla/structured fields — it never blocks.
- **Vendor abstraction:** `OcrService` interface lets us swap Cloud Vision for an LLM-vision model (Open Question Q1) without touching the feature.
- **Handwriting** (P1) goes through the same pipeline but forces stricter review.

---

## 6. Offline-First Reminder & Alarm Engine (highest-risk component)

Reminders **must** fire with no internet, after app kill, and after reboot. This is non-trivial because of OS background restrictions.

### Android
- Schedule via **`AlarmManager` exact alarms** (`setExactAndAllowWhileIdle`) for time-critical medicine reminders; `flutter_local_notifications` for delivery + actions + channels.
- **Android 12+ (`SCHEDULE_EXACT_ALARM`)**: request the exact-alarm permission; guide users who deny it.
- **Reboot recovery:** `RECEIVE_BOOT_COMPLETED` receiver re-registers all pending alarms from the **local mirror** on boot (no Firebase init required).
- **Doze / battery optimization:** detect aggressive OEM battery managers (Xiaomi, Oppo, Realme, Samsung — common in BD) and prompt the user to whitelist the app; use high-importance notification channels.
- **Channels:** separate channels per reminder type so users can tune behavior; medicine = high importance + sound + (optional) full-screen alarm UI.

### iOS
- Use **`UNUserNotificationCenter`** scheduled local notifications with actions.
- **Hard constraint:** iOS allows only **64 pending local notifications** per app. For heavy multi-medicine users this can overflow → implement a **rolling re-scheduling window** (schedule the next N days, top up on app open / background refresh) and surface this limit in design (Open Question Q3).
- No true background alarm execution → rely on scheduled notifications, not arbitrary background code.

### Shared design
- `ReminderScheduler` is a **platform-abstracted interface**; Android/iOS implementations sit behind it.
- All schedules are **reconstructable from the local mirror** via stored recurrence rules — the OS scheduler is treated as a cache, not the source of truth.
- **Missed-event detection:** a grace-window check (on app open + periodic background where allowed) marks unconfirmed reminders as missed and triggers follow-up nudges (PRD P0-9).

---

## 7. Bilingual & Bangla OCR (i18n)

- **UI localization:** `intl` + ARB files (`en`, `bn`); a `LocaleController` (GetX) drives runtime switching with no restart.
- **Bangla typography:** bundle a high-quality Bangla-capable font (e.g. a Noto Bengali / open Bangla font) to guarantee correct conjunct rendering across devices; never rely on system fonts alone.
- **Localized content:** diet/exercise plans, notification text, and disclaimers are localized, not just UI chrome.
- **Bangla OCR:** routed to Cloud Vision (Bengali printed support). Script detection decides routing automatically. Numerals: handle both Western (0-9) and Bangla (০-৯) digits in dose/frequency parsing.
- **Formatting:** locale-aware dates/times and number formatting throughout.

---

## 8. Backend (Firebase — serverless)

No self-managed server. Firebase services, accessed behind repository interfaces so the app remains testable and the backend swappable.

| Service | Purpose |
|---|---|
| **Firebase Auth** | Account + login (email / phone OTP / Google). Phone OTP is well-suited to the BD market. |
| **Cloud Firestore** | Primary data store with offline persistence; real-time auto-sync across devices; no custom sync code needed. |
| **Firebase Storage** | Stores prescription images (only after explicit consent); referenced by URL from the Firestore record. |
| **Cloud Functions** | `extractPrescription` callable: image → Cloud Vision → LLM structuring → structured JSON. Keeps API keys server-side and lets us swap OCR/LLM vendors without a client update. |
| **Cloud Messaging (FCM)** | Cross-device/caregiver nudges only — **not** the primary reminder path (local alarms are). |
| *(future)* Functions + Firestore | Drug-DB lookups, adherence report (PDF) generation, caregiver fan-out. |

### Why Firebase fits this app
- **Built-in offline + sync.** Firestore's offline persistence directly serves the offline-first requirement for *data* (the alarm *firing* is handled separately by the local mirror + OS scheduler).
- **No server ops.** Faster to ship and cheaper to run at MVP scale; scales without infra work.
- **Security via rules, not middleware.** Per-user data isolation is declared in Firestore Security Rules.

### Key trade-offs to keep in mind
- **Querying limits:** Firestore has no rich joins/aggregations; model data as denormalized per-user subcollections (already reflected in §4).
- **Cost model:** billed per read/write/delete — design listeners and pagination deliberately to avoid runaway reads.
- **OCR still needs network:** the `extractPrescription` function requires connectivity; the on-device ML Kit fallback (English) keeps capture usable offline.

### Firestore Security Rules (principle)
All documents under `users/{uid}/**` are readable/writable only when `request.auth.uid == uid`. Cloud Functions run with admin privileges for the OCR proxy and validate inputs. No client ever holds OCR/LLM API keys.

---

## 9. Security & Privacy

- **Local-first for reminders:** the reminder mirror and sensitive prefs are stored on-device; encrypt the local store (e.g. Hive encryption / SQLCipher) and the cached data.
- **Firestore isolation:** Security Rules restrict every document to its authenticated owner (`users/{uid}/**`); no cross-user access is possible.
- **Explicit consent** before any image or health data leaves the device (cloud OCR / cloud sync); offer an on-device-only English mode where feasible.
- **Data minimization:** Cloud Functions receive only the image needed for OCR; nothing extra is uploaded.
- **In transit:** all Firebase traffic is TLS; Cloud Functions validate and sanitize inputs.
- **Storage hygiene:** prescription images in Firebase Storage are owner-scoped via Storage Security Rules; users can delete images, which removes both the Storage object and the Firestore reference.
- **Deletion / portability:** user can delete prescriptions/images locally and from the cloud; account deletion purges the `users/{uid}` tree.
- **PHI awareness:** health data is sensitive — note that standard Firebase is not HIPAA-covered by default; if regulatory coverage is ever required, that's a separate compliance track (flagged, not assumed for v1 BD launch).
- **Disclaimers & no-diagnosis stance** enforced at the product level (PRD §8).

---

## 10. Non-Functional Requirements

| Attribute | Target |
|---|---|
| Reminder reliability | ≥ 99% fire rate incl. offline + post-reboot |
| Cold start | < 2.5 s on mid-range Android |
| OCR round-trip (cloud) | < 6 s typical on 4G |
| Crash-free sessions | ≥ 99.5% |
| Accessibility | WCAG-aligned contrast, scalable text, large tap targets |
| Min OS | Android 8+ / iOS 14+ (confirm) |
| Localization | 100% of user-facing strings in EN + BN |

---

## 11. Testing Strategy

- **Unit:** domain use-cases (BMI calc, recurrence generation, dose-to-schedule mapping, Bangla numeral parsing).
- **Widget:** review/edit screen states, localized rendering, empty/error states.
- **Integration:** end-to-end capture → extract → confirm → schedule; offline reminder firing; reboot recovery.
- **Device matrix:** prioritize popular BD Android OEMs with aggressive battery managers; verify exact-alarm + Doze behavior.
- **OCR accuracy harness:** a labeled set of EN + BN prescriptions to track extraction quality and regression.

---

## 12. Key Technical Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| OEM battery managers kill alarms | Missed reminders | Whitelist prompts, exact alarms, boot re-registration, reliability instrumentation |
| iOS 64-notification limit | Overflow for heavy users | Rolling re-scheduling window + top-up on app open |
| Bangla/handwriting OCR errors | Wrong meds scheduled | Mandatory review, confidence flags, conservative defaults |
| Cloud OCR cost/latency | UX + budget | On-device fast path; vendor abstraction behind Cloud Functions for cheaper swaps |
| Firestore read/write cost at scale | Budget | Denormalized per-user model, pagination, careful listeners, cache-first reads |
| Firebase vendor lock-in | Future migration cost | Repository interfaces wrap all Firebase calls so the data layer is replaceable |
| PHI handling | Privacy/legal | Local-first reminders, encryption, Security Rules, explicit consent; note standard Firebase ≠ HIPAA |
| Android exact-alarm permission denied | Inexact reminders | Detect, explain, offer inexact fallback with clear warning |

---

## 13. Reusability / White-Label Notes

- Central `config` module: brand colors, app name, logo, enabled features (feature flags), default locale.
- All vendor integrations (OCR, Firebase data/auth/storage, push) behind interfaces → swappable per deployment, and the Firebase layer is replaceable without touching features.
- Each white-label deployment uses its own Firebase project (separate `google-services.json` / `GoogleService-Info.plist`) — data isolation and billing per client out of the box.
- Design system fully tokenized (see Design doc) → re-skin without touching feature code.
- This positions MediSync as a re-deployable health-app template, consistent with a CodeCanyon-grade, modular goal.
