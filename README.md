# MediSync

> Snap your prescription — MediSync remembers it, reminds you, and helps you stay on track.

An offline-first Flutter health companion: prescription OCR → mandatory review →
reliable medication / meal / water / sleep reminders that fire **without
internet** and survive reboot, plus BMI-based diet & exercise plans. Bilingual
Bangla / English. Built modular and white-label-ready.

See [PRD](MediSync_PRD.md), [TRD](MediSync_TRD.md), [Design](MediSync_Design.md),
and the [implementation plan](IMPLEMENTATION_PLAN.md).

---

## Status of this build

This is the **P0 (Must-Have) feature pass**, authored as a complete Flutter
codebase. It has **not been compiled or run** yet (the authoring machine had no
Flutter toolchain). Treat the first `flutter analyze` / `flutter run` as the
verification step and fix any environment-specific issues that surface.

### What's implemented
- Feature-first clean architecture (`core/` + `domain/` + `features/`), GetX DI.
- Tokenized design system (light/dark, Bangla-aware typography) — `core/design_system`.
- Full EN/BN localization (`intl` + ARB) with runtime switching — `core/localization`.
- Offline reminder/alarm engine: `flutter_local_notifications` + exact alarms +
  boot re-registration + iOS rolling 64-notification window + missed-event
  follow-up — `core/notifications`.
- Hive local mirror as the reminder source of truth; Firestore write-through
  mirror behind repositories — `core/data`, `core/firebase`.
- OCR pipeline: on-device ML Kit + script detection + rule-based structurer with
  confidence flags; cloud Vision/LLM behind an interface — `core/ocr`.
- Features: onboarding, Today dashboard, capture→review→**schedule preview**→
  confirm, meal/water/sleep settings, BMI plan, profile/permissions.
- Auth (P1-1): email/password + anonymous + phone-OTP behind `AuthRepository`
  (offline-safe — app works fully signed-out). Account section in Profile.
- Deployable backend config: `firebase.json`, `firestore.rules`,
  `firestore.indexes.json`, `storage.rules`, `functions/`.

### What's stubbed / needs follow-up
- `lib/firebase_options.dart` is a **placeholder** — run `flutterfire configure`.
  Until then the app runs **offline-only** (Hive is the source of truth).
- Cloud OCR + LLM structuring (`functions/index.js`, `CloudOcrService`) — not
  deployed; Bangla images fall back to on-device English OCR + manual entry.
- Bundled fonts are **not** included (binaries) — see `assets/fonts/README.md`.
- Native alarm reliability across BD OEMs, exact-alarm behavior, and the iOS
  window all need on-device verification (TRD §11 device matrix).

---

## Getting started

### 1. Prerequisites
- Flutter SDK (stable, Dart ≥ 3.3). Verify with `flutter doctor`.
- Android Studio / Xcode for device or emulator.

### 2. Generate the platform projects
This repo ships `lib/`, `pubspec.yaml`, the Android manifest, and config docs —
but not the full generated `android/` & `ios/` Gradle/Xcode projects. Generate
them **without overwriting** the source:

```bash
cd MediSync
flutter create --org com.medisync --project-name medisync .
```

Then:
- Re-apply [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml)
  if `flutter create` overwrote it (permissions + boot receivers).
- Apply [`android/GRADLE_NOTES.md`](android/GRADLE_NOTES.md) (minSdk 26, desugaring).
- Apply [`ios/Runner/Info.plist.additions.md`](ios/Runner/Info.plist.additions.md).

### 3. Add fonts
Download the fonts listed in [`assets/fonts/README.md`](assets/fonts/README.md)
(or temporarily remove the `fonts:` block in `pubspec.yaml`).

### 4. Install deps + generate localizations
```bash
flutter pub get          # also runs gen-l10n (generate: true) → AppLocalizations
```

### 5. (Optional) Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure    # generates lib/firebase_options.dart + platform files
firebase deploy --only firestore:rules   # firestore.rules
```
Skip this and the app runs offline-only.

### 6. Run
```bash
flutter run
```

---

## Architecture

```
lib/
├── core/            # config, design_system, localization, notifications,
│                    # ocr, data (Hive + Firestore repos), firebase,
│                    # permissions, routing, di, utils
├── domain/          # entities, enums, repository interfaces (vendor-agnostic)
├── features/        # onboarding, dashboard, prescription, reminders,
│                    # bmi_plan, profile  (data / domain / presentation)
└── main.dart
```

**Why the local mirror?** The OS alarm scheduler and boot receiver read reminders
straight from Hive, so reminders fire even before Firebase initializes and with
no network. Firestore is the system of record + sync layer; the mirror exists to
make the alarm engine bullet-proof (TRD §1, §6).

## Testing (next)
Priority unit tests (TRD §11): `BmiCalculator`, `RecurrenceRule`,
`ReminderGenerator` (dose→schedule), `BanglaNumerals`, `TimelineBuilder`.

## White-label
Swap `AppConfig.mediSync` (brand, locale, feature flags) and the design tokens in
`core/design_system/tokens.dart`; each deployment uses its own Firebase project.
