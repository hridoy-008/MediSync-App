# MediSync — Implementation Plan

**Derived from:** MediSync_PRD.md, MediSync_TRD.md, MediSync_Design.md
**Target of this pass:** All P0 (Must-Have) features, full Flutter codebase authored by hand.
**Decisions locked for this pass:**
- Stack: Flutter + GetX + feature-first clean architecture (per TRD).
- Backend: **Firebase wired behind repository interfaces** (Auth/Firestore/Storage/Functions). `firebase_options.dart` is a placeholder until `flutterfire configure` is run.
- OCR: **on-device ML Kit** as the working path; cloud Vision/LLM behind `OcrService` + `PrescriptionStructurer` interfaces, stubbed for later.
- Local source-of-truth for reminders: **Hive** mirror read by the alarm engine + boot receiver (Firebase-independent).
- Cannot compile/test in this environment (no Flutter SDK) — code is authored for correctness and built later.

---

## Architecture (feature-first clean)

```
lib/
├── core/
│   ├── config/          # AppConfig, feature flags, white-label theme config
│   ├── design_system/   # tokens, theme, reusable components
│   ├── localization/    # intl/ARB, LocaleController, Bangla font
│   ├── notifications/   # ReminderScheduler interface + local-notif/alarm impl + boot
│   ├── ocr/             # OcrService + PrescriptionStructurer interfaces + ML Kit/stub impls
│   ├── data/            # Hive local mirror, repository interfaces + Firestore/Hive impls
│   ├── firebase/        # Firebase init + service wrappers
│   ├── permissions/     # notification, exact-alarm, battery, camera
│   ├── routing/         # GetX routes & pages
│   └── utils/           # Result/Failure, recurrence, bmi math, logging, extensions
├── domain/              # shared entities + enums (cross-feature models)
├── features/
│   ├── onboarding/
│   ├── dashboard/       # Home / Today
│   ├── prescription/    # capture → extract → review/edit → history
│   ├── reminders/       # medicine/meal/water/sleep schedules + logs
│   ├── meal/            # meal-time config
│   ├── hydration_sleep/ # water & sleep config
│   ├── bmi_plan/        # BMI calc + diet/exercise plan
│   └── profile/         # profile, language, permissions, theme, privacy
└── main.dart
```

## Build order (maps to PRD §11 phasing, compressed into one pass)

1. **Foundation** — pubspec, config, utils, design system, localization, DI/bindings, routing.
2. **Domain models** — all core entities + enums + Hive adapters.
3. **Data layer** — Hive local mirror + repository interfaces + Firestore/Hive impls.
4. **Notification/alarm engine** (highest risk) — scheduler interface, channels, exact alarms, boot re-registration, iOS rolling window, missed-event follow-up.
5. **OCR pipeline** — OcrService (ML Kit) + structurer stub + confidence flags.
6. **Features** — onboarding, dashboard, prescription capture/review, reminders, meal, hydration/sleep, BMI plan, profile.
7. **Platform config** — AndroidManifest (permissions, boot receiver), Info.plist, Gradle notes.
8. **Docs** — README with setup, Firebase wiring, run instructions, and what's stubbed.

## P0 coverage checklist

| P0 | Feature | Where |
|---|---|---|
| P0-1 | Prescription capture (camera/gallery, crop) | features/prescription |
| P0-2 | Extraction + mandatory review, confidence flags | features/prescription + core/ocr |
| P0-3 | Bangla & English OCR routing | core/ocr (ML Kit local + cloud stub route) |
| P0-4 | Medication reminders + quick actions | core/notifications + features/reminders |
| P0-5 | Offline-first reminders (kill/reboot safe) | core/notifications + Hive mirror |
| P0-6 | Meal-time reminders + food-relative meds | features/meal + reminders |
| P0-7 | Water & sleep reminders | features/hydration_sleep |
| P0-8 | BMI → diet & exercise plan | features/bmi_plan + core/utils/bmi |
| P0-9 | Missed-event follow-up | core/notifications (grace window) |
| P0-10 | Full bilingual UI (EN/BN) | core/localization |
| P0-11 | Local persistence & history | core/data (Hive) |

## Known stubs / follow-ups (verification needed once toolchain exists)
- `firebase_options.dart` placeholder — run `flutterfire configure`.
- Cloud Vision + LLM structuring behind interfaces — return rule-based/mock structure for now.
- Native boot receiver wiring + exact-alarm behavior — needs device testing across BD OEMs.
- iOS 64-notification rolling window — implemented logically, needs device validation.
