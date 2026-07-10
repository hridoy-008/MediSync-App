# MediSync — Product Requirements Document (PRD)

**Version:** 1.0 (Draft)
**Owner:** Masum
**Status:** For review
**Last updated:** 23 June 2026

> **Working assumptions** (to be confirmed): Flutter (Android + iOS) + **Firebase** (Cloud Firestore, Auth, Cloud Functions, Storage, FCM), GetX, feature-first clean architecture. Bangladesh-first, bilingual Bangla/English. Hybrid OCR (on-device + cloud via Cloud Functions + LLM structuring) with mandatory user review. **Offline-first:** Firestore offline persistence for data + a Firebase-independent local mirror so reminders fire offline and survive reboot. Built modular / white-label-ready.

---

## 1. Product Summary

MediSync is a personal health-companion mobile app that turns a photo of a prescription into a structured, actionable care plan. It extracts medicines, tests, and instructions from a prescription image, then schedules reliable medication, meal, water, and sleep reminders that fire **even without internet**. It adds a personalized diet and exercise plan derived from the user's BMI, and follows up when the user misses something. The app is bilingual (Bangla / English), including Bangla OCR for locally written prescriptions.

### One-line positioning
*"Snap your prescription — MediSync remembers it, reminds you, and helps you stay on track."*

---

## 2. Problem Statement

People — especially elderly patients and those managing chronic conditions — routinely forget to take medicines on time, miss prescribed tests, and lose track of paper prescriptions. Manually entering a medication schedule into a generic reminder app is tedious and error-prone, and most apps assume constant connectivity and English literacy, which excludes a large part of the Bangladeshi market. The cost of not solving this is real: missed doses, poor treatment adherence, and avoidable health deterioration.

---

## 3. Goals

1. **Reduce manual setup friction:** A user can go from a prescription photo to a working reminder schedule in under 2 minutes, with no typing for the happy path (beyond confirming extracted data).
2. **Improve medication adherence:** Drive a measurable increase in on-time doses through reliable, offline-capable reminders and missed-dose follow-ups.
3. **Serve the local market authentically:** Full Bangla/English experience, including Bangla prescription reading, so non-English-first users get equal value.
4. **Be trustworthy and safe:** No medication or test reminder is ever created from raw OCR without explicit user confirmation; all health guidance carries clear medical disclaimers.
5. **Be reusable:** Ship as a modular, configurable codebase that can be re-skinned and re-deployed for other health products with minimal change.

---

## 4. Non-Goals (v1)

1. **Not a diagnosis or telemedicine tool.** No symptom-to-diagnosis engine, no doctor video calls in v1. *(Too high-risk/complex; separate initiative.)*
2. **Not a clinical drug-interaction authority.** A basic interaction/allergy warning may come later, but v1 will not claim clinical-grade interaction checking. *(Requires a vetted drug database and liability review.)*
3. **Not a pharmacy/e-commerce platform.** No in-app medicine ordering or payments in v1. *(Out of core problem scope.)*
4. **Not a multi-patient hospital system.** Caregiver/family multi-profile is a fast-follow, not v1 core. *(Adds account-model complexity; validate single-user first.)*
5. **No automated handwriting guarantee.** We will support handwritten prescriptions on a best-effort basis with heavy user review, not as a guaranteed-accurate feature. *(Handwriting OCR is inherently unreliable.)*

---

## 5. Target Users & Personas

| Persona | Description | Primary needs |
|---|---|---|
| **Rina, 34 — the busy caregiver** | Manages her own and her father's medication. Smartphone-comfortable, bilingual. | Fast prescription capture, reliable reminders, eventually managing a second profile. |
| **Mr. Karim, 62 — the chronic patient** | Diabetes + hypertension. Limited English, prefers Bangla. Forgets doses. | Large Bangla UI, loud/persistent reminders, missed-dose nudges, simple flows. |
| **Sadia, 27 — the health-conscious user** | No chronic illness; wants meal/water/sleep routine + diet & exercise from BMI. | Habit reminders, BMI-based diet/exercise plan, progress tracking. |

---

## 6. User Stories

### Prescription capture & extraction
- As a patient, I want to photograph or upload my prescription so that the app can read it without me typing.
- As a patient, I want to **review and edit** the extracted medicines, doses, tests, and instructions so that I can correct OCR mistakes before anything is scheduled.
- As a Bangla-first user, I want the app to read Bangla prescriptions so that I get the same benefit as English users.
- As a patient, I want my past prescriptions saved so that I can revisit or re-use them.

### Reminders (medication, meal, water, sleep)
- As a patient, I want medicine reminders generated from my prescription so that I take doses on time.
- As a patient, I want to set my meal times so that the app reminds me to eat — and times medicines correctly around meals (before/after food).
- As a user, I want water and sleep reminders so that I build healthier daily habits.
- As a patient, I want reminders to fire **even with no internet** so that I never miss a dose due to connectivity.
- As a patient, I want a follow-up nudge if I miss or don't confirm a dose so that I can catch up.

### BMI, diet & exercise
- As a user, I want to enter my height, weight, age, sex, and activity level so that the app computes my BMI.
- As a user, I want a personalized diet chart and exercise plan based on my BMI so that I have clear daily guidance.
- As a user, I want the plan in Bangla or English so that I can actually follow it.

### Bilingual & accessibility
- As a Bangla-first user, I want the entire app in Bangla so that I'm comfortable using it.
- As an older user, I want large text and clear contrast so that I can read reminders easily.

### Edge cases
- As a user, when OCR confidence is low, I want the app to clearly flag uncertain fields so that I double-check them.
- As a user, if I deny notification/alarm/battery permissions, I want clear guidance so that reminders still work.
- As a user, with no prescription yet, I want a helpful empty state so that I know what to do first.

---

## 7. Requirements

### 7.1 Must-Have (P0)

**P0-1 Prescription capture**
Capture via camera or pick from gallery; basic crop/rotate/enhance.
*Acceptance:* Given a user taps "Add prescription," when they capture or select an image, then they can crop/rotate and proceed to extraction.

**P0-2 Extraction + mandatory review**
Run OCR + structuring to detect medicines (name, dose, frequency, duration, before/after food), tests, and free-text instructions. Present an editable review screen; low-confidence fields are visually flagged. **Nothing is scheduled until the user confirms.**
*Acceptance:* Given extraction completes, when the review screen loads, then every detected item is editable and uncertain items are flagged; no reminder exists until the user taps "Confirm."

**P0-3 Bangla & English OCR**
Detect and read both Bangla and English printed prescriptions; route to the appropriate OCR engine automatically.
*Acceptance:* Given a Bangla printed prescription, when extraction runs, then Bangla text is recognized and shown for review.

**P0-4 Medication reminders**
Generate schedules from confirmed data; user can confirm "taken" / "snooze" / "skip" from the notification.
*Acceptance:* Given confirmed medicines, when each scheduled time arrives, then a notification fires with quick actions; the dose is logged accordingly.

**P0-5 Offline-first reminders**
All reminders (medicine, meal, water, sleep) fire reliably with no internet, surviving app kill and device reboot.
*Acceptance:* Given the device is offline and the app is not running, when a scheduled time arrives (including after a reboot), then the reminder still fires.

**P0-6 Meal-time reminders**
User sets meal times; app reminds and aligns "before/after food" medicines to them.
*Acceptance:* Given meal times are set, when a meal time arrives, then a reminder fires; medicines marked "after food" schedule relative to the relevant meal.

**P0-7 Water & sleep reminders**
Configurable water interval/targets and sleep/bedtime + wake reminders.
*Acceptance:* Given water and sleep settings, when each trigger occurs, then the corresponding reminder fires; settings are editable.

**P0-8 BMI → diet & exercise plan**
Compute BMI from height/weight/age/sex/activity; produce a diet chart + exercise plan mapped to the BMI category, localized.
*Acceptance:* Given valid inputs, when the user requests a plan, then BMI + category and a localized diet/exercise plan are shown with a medical disclaimer.

**P0-9 Missed-event follow-up**
If a dose/meal isn't confirmed within a grace window, send a follow-up nudge and log the miss.
*Acceptance:* Given a reminder is unconfirmed after the grace window, when it elapses, then a follow-up notification is sent and the miss is recorded.

**P0-10 Full bilingual UI**
Entire app available in Bangla and English; user-switchable; correct Bangla typography.
*Acceptance:* Given the user switches language, when any screen renders, then all UI strings appear in the selected language with proper Bangla rendering.

**P0-11 Local data persistence & history**
Offline local DB stores prescriptions, schedules, logs, and settings as the source of truth.
*Acceptance:* Given data is created offline, when the app restarts, then all data persists and is viewable.

### 7.2 Nice-to-Have (P1 — fast follow)

- **P1-1 Cloud account & cross-device sync** via Firebase Auth + Firestore (real-time sync is largely built-in; reminder mirror stays local for offline firing).
- **P1-2 Adherence reports / streaks**, exportable as PDF to show a doctor.
- **P1-3 Vitals & lab-result tracking** (BP, sugar, weight) with trend charts, tied to detected tests.
- **P1-4 Medicine inventory & refill alerts.**
- **P1-5 Appointment reminders.**
- **P1-6 Handwritten-prescription best-effort mode** with stronger review prompts.

### 7.3 Future Considerations (P2 — design for, don't build)

- **P2-1 Caregiver / family multi-profile** with miss alerts to a caregiver.
- **P2-2 Basic drug-interaction & allergy warnings** (needs vetted DB + legal review).
- **P2-3 Emergency SOS + Medical ID.**
- **P2-4 Generic-alternative suggestions** (DGDA/MIMS data).
- **P2-5 Telemedicine / doctor integration.**

*(Architectural note: the data model, OCR pipeline, and account model are designed so these slot in without rework — see TRD.)*

---

## 8. Safety, Trust & Compliance

- **No auto-scheduling from raw OCR.** Human confirmation is a hard requirement (P0-2).
- **Disclaimers** on diet, exercise, and any medication-related output: *"For informational purposes only; not a substitute for professional medical advice."*
- **Conservative defaults:** uncertain OCR fields are flagged, never silently accepted.
- **Privacy:** health data is sensitive; default to local storage, explicit consent before any cloud upload, encryption at rest and in transit (detailed in TRD).

---

## 9. Success Metrics

### Leading indicators (days–weeks)
- **Activation:** % of new users who capture ≥1 prescription and confirm a schedule. *Target: 60% within first session.*
- **Setup time:** median time from "Add prescription" to confirmed schedule. *Target: < 2 min.*
- **Reminder reliability:** % of scheduled reminders that actually fire (instrumented). *Target: ≥ 99%, including offline.*
- **OCR review correction rate:** % of fields users edit (quality signal). *Track; high rates flag extraction issues.*

### Lagging indicators (weeks–months)
- **Adherence:** on-time dose-confirmation rate per active user. *Target: ≥ 75%.*
- **Retention:** D30 retention of activated users. *Target: ≥ 40%.*
- **Language reach:** share of active users using Bangla UI (validates localization value).
- **Satisfaction:** in-app rating / NPS. *Target: ≥ 4.3 / 5.*

---

## 10. Open Questions

| # | Question | Owner |
|---|---|---|
| Q1 | Cloud OCR vendor behind Cloud Functions: Google Cloud Vision vs. an LLM-vision model for Bangla — cost vs. accuracy? | Engineering |
| Q2 | Drug name normalization — do we license a Bangladeshi medicine database (DGDA/MIMS) now to enable later interaction checks? | Stakeholder / Legal |
| Q3 | iOS reminder limits (64 pending local notifications) — acceptable for heavy multi-med users, or do we need a rolling-rescheduling strategy? | Engineering |
| Q4 | Is single-user the right v1 account model, or do we need caregiver multi-profile sooner for the target market? | Stakeholder |
| Q5 | Diet/exercise plan source: static rule-based tables vs. AI-generated — and who validates clinical safety? | Stakeholder / Design |
| Q6 | White-label depth required for CodeCanyon (theming only vs. full config-driven feature toggles + per-client Firebase project)? | Stakeholder |
| Q7 | Firestore cost ceiling at target scale — acceptable, or cap free-tier usage / paginate aggressively? | Engineering |

---

## 11. Timeline & Phasing

| Phase | Scope | Outcome |
|---|---|---|
| **P0 — Foundation** | Modular skeleton, design system, **Firebase setup (Auth/Firestore/Storage/Functions)**, local reminder mirror, **notification/alarm engine**, i18n framework | Reminders can fire offline; app shell ready |
| **P1 — Capture & Extract** | Camera/gallery, OCR routing (EN/BN), LLM structuring, **review/edit screen**, history | Prescription → structured data → confirmed |
| **P2 — Reminders** | Medicine + meal + water + sleep reminders, quick actions, missed-event follow-ups | Full reminder suite live |
| **P3 — Diet & Exercise** | BMI input, plan generation, localization, disclaimers | Personalized plans |
| **P4 — Differentiators (P1 list)** | Adherence reports, vitals, inventory, sync | Stickiness features |
| **P5 — Hardening & launch** | Testing, accessibility, performance, store/marketplace prep | Release-ready |

> The **notification/alarm engine is the highest-risk component** and is intentionally built first, because offline reliability across Android background restrictions and iOS limits underpins the entire value proposition.
