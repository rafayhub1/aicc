# AICC — Mobile App Build Plan (Milestone-Based)

## Where things actually stand right now

Two things already exist and should **not** be rebuilt:

1. **`aicc-data-service`** — a FastAPI backend, deployed (or being deployed) to Render,
   backed by its own dedicated Firestore project (`aicc-dummy-data`, region
   `asia-south1`). It exposes REST endpoints for students, courses,
   notifications, and documents, seeded with 72 dummy students across 24
   cohorts (departments `BSPSY` / `BSCS` / `BBA` × semesters 1-4 × sections A/B).
   It also serves two public, printable HTML pages per student: a fee
   challan and a roll number slip.
2. **The `aicc/` Flutter project** — already created, with Flutter/Android
   tooling verified end to end (`flutter doctor` clean, a real device
   connected via USB), and Firebase already wired up via `flutterfire
   configure` against its **own separate Firebase project** (referred to
   below as "the mobile Firebase project"). `firebase_core`, `firebase_auth`,
   `cloud_firestore`, `provider`, `intl`, and `google_fonts` are already in
   `pubspec.yaml` and `main.dart` already calls `Firebase.initializeApp()`.

This plan is entirely about building **features on top of that**, not
redoing setup. If any milestone below seems to ask you to recreate something
that already exists, stop and flag it rather than doing it again.

---

## How Cursor must work through this plan

This is not optional — follow both rules for every milestone:

1. **One milestone at a time, then stop.** Finish a milestone, run it,
   confirm it visually works, summarize in plain language what was built,
   and explicitly ask "ready to continue to Milestone N?" before starting
   the next one. Never build two milestones in the same pass, even if one
   looks trivial.
2. **Call out every manual step the moment it comes up.** Anything outside
   the code itself — a Firebase console click, an environment variable, a
   new package install, a Render setting, a value only the user can supply
   (like a live API URL) — stop and give exact, numbered, plain-language
   instructions for what to click or type, written for someone with no
   prior cloud/Firebase experience. Never assume this can be skipped or
   figured out silently.

---

## Two architectures working together

- **Backend calls** (`http` package) → `aicc-data-service` on Render → its
  own Firestore (`aicc-dummy-data`). Read-only from the mobile app except
  one action: marking a notification read.
- **Mobile Firebase project** (already configured) → Firebase Auth for
  login/signup, plus Firestore collections for teacher tracking, chat
  history, and mobile-generated activity events (see Notifications below).
  This project knows nothing about the backend's data and vice versa.

---

## Packages to add (on top of what's already installed)

```
flutter pub add http
flutter pub add webview_flutter
flutter pub add speech_to_text
flutter pub add flutter_tts
```
Don't hand-pick version numbers for these — `flutter pub add` resolves the
current stable release automatically. Keep the existing pinned versions for
everything already in `pubspec.yaml` untouched.

Voice assistant is a **core feature**, not a stretch add-on — it's built
into Milestone 9, right after text chat works, not deferred to the end.

---

## Data models

### From the backend API (`lib/models/`)
Field names below are based on the build plan — **confirm exact casing
against the live interactive docs at `<your-render-url>/docs` before
finalizing these classes**, since this plan wasn't generated from the raw
source file.

```
Student:            registrationNumber, department, semester, section, cgpaOverall
                     (name — confirm this field exists on the backend; if it
                     doesn't, it needs adding + reseeding before Milestone 7)
Course:              id, code, name, semester, attendancePercent
AppNotification:     id, type ("fee_challan_ready" | "roll_slip_ready" | "sign_in" | "other"),
                     title/body (confirm exact field), read (bool), timestamp
StudentDocument:     id, docType ("fee_challan" | "roll_number_slip"),
                     status ("pending" | "ready"), fileUrl
Catalog:             departments, semesters, sections (for any future dropdowns)
```

### In the mobile Firebase project (`lib/models/`)
```
Faculty:
  full_name: string
  department: string
  designation: string
  subjects: array<string>          // courses/subjects this teacher teaches
  class_schedule: string           // e.g. "Mon/Wed 10-12, Tue/Thu 2-4 PM"
  consultation_hours: string       // free/office time
  days_off: array<string>          // e.g. ["Saturday", "Sunday"]
  email: string
  phone: string
  office_building: string          // e.g. "CS-BLOCK", "ADMIN"
  office_room: string              // e.g. "Room 204" / "Staff Room B"
  current_status: string           // "In Office" | "In Class" | "Unavailable"

ChatSession: id, user_id, title, created_at
ChatMessage: id, session_id, role ("user"|"assistant"), content, created_at

ActivityEvent:                     // powers the non-backend notifications
  user_id, type ("signup"|"login"|"logout"|"chat_completed"), timestamp
```

---

## Where each notification actually comes from

| Shown to student | Source |
|---|---|
| Fee challan ready | Backend API (`type: fee_challan_ready`) |
| Roll number slip ready | Backend API (`type: roll_slip_ready`) |
| Chat completed | Mobile Firestore `ActivityEvent`, written when a chat session ends |
| Signed up successfully | Mobile Firestore `ActivityEvent`, written on signup |
| Logged in | Mobile Firestore `ActivityEvent`, written on login |
| Logged out | Mobile Firestore `ActivityEvent`, written on logout |

The Notifications screen merges both sources into one list, sorted by time.

---

## Design system (carry forward, then elevate)

Same brand palette as the original spec — Primary `#0b3d66`, Primary light
`#1b5f9c`, Accent `#2e9e6c`, Background `#eef1f4`, card white, muted text
`#6b7684`, danger `#c0392b`, rounded corners (10-16px cards, 20-24px pills,
circular avatars/FABs), Google Fonts "Inter."

"Attractive" is an explicit requirement, so go beyond static screens:
smooth page transitions, skeleton/shimmer loading states (not blank
screens) while API calls are in flight, friendly empty states (e.g. "No
notifications yet" with an icon, not a blank list), and consistent
iconography across every module.

---

## Milestones

### Milestone 0 — Environment & backend connectivity check
Confirm `flutter run` still launches cleanly on the connected phone.
Confirm the backend is reachable at its **public Render URL** (not
localhost — hitting a local server from a real phone over USB needs extra
network setup that isn't worth the complexity here). If it isn't deployed
yet, **stop and walk the user through the Render deploy steps** before
continuing. Add one temporary test button that calls `GET /health` and
`GET /api/catalog` and prints the result, just to prove connectivity works
end to end. Remove the test button once confirmed.

### Milestone 1 — Design system & app shell foundations
`core/theme.dart` with the palette and text styles above. Build reusable
widgets you'll reuse everywhere: a primary button, a card container, a
loading skeleton, an empty-state widget, a status pill. A simple branded
splash screen.

### Milestone 2 — Data models & API client layer
All model classes from above. `core/api_config.dart` holding the backend
base URL as a single constant (placeholder value until Milestone 0's URL
is confirmed). `services/api_service.dart` wrapping every backend call
listed in this plan. Nothing user-facing yet — this is plumbing.

### Milestone 3 — Shared document viewer
A reusable widget (`widgets/document_webview.dart`) that opens a given URL
(the backend's fee-challan/roll-slip pages) in an in-app WebView, with a
loading indicator and a basic error state if the page fails to load. Built
standalone here because Chat, Notifications, and the dashboard all need it
later.

### Milestone 4 — Sign up
Fields: registration number, password (+ confirm). On submit: call
`GET /api/students/{regNo}` against the backend first — if not found, show
"Registration number not found in university records," don't create an
account. If found, create a Firebase Auth account in the mobile project
using a deterministic internal email (e.g.
`{regno-lowercase}@aicc-demo.local`) with the entered password, write a
`signup` ActivityEvent, then move to Login. **You'll need at least one real
seeded registration number to test this against** — check the admin portal
or seed script output for one.

### Milestone 5 — Login + session persistence
Registration number + password → compute the same internal email →
`signInWithEmailAndPassword`. One generic error message on failure (don't
reveal which part was wrong). Firebase Auth persists sessions
automatically, so returning users should land straight on the dashboard
without re-entering credentials. Write a `login` ActivityEvent on success.

### Milestone 6 — Navigation shell (burger menu)
A drawer, opened/closed by a button in the app bar, listing in this exact
order: Home/Dashboard, New Chat, Chat History, Notifications, Teacher
Tracking, Indoor Navigation (grayed out / "Coming soon" until Milestone
14), then Log Out at the bottom. Wrap placeholder screens for each item
first — content comes in later milestones.

### Milestone 7 — Home / Dashboard
Welcome message with the student's name, registration number, department,
semester, section, CGPA (`GET /api/students/{id}`), and an attendance
figure calculated as the average `attendancePercent` across the current
semester's courses (`GET /api/students/{id}/courses?semester=`) — this is
computed client-side, not a field the API returns directly.

### Milestone 8 — AI Chat Assistant ("New Chat")
Rule-based responder (as in the original plan) matching keywords for FAQs,
policies/regulations from a small hardcoded knowledge base, plus live-data
questions routed to the right source:
- Documents/fee/roll-slip questions → backend API, opens Milestone 3's
  viewer when ready
- Course/attendance questions → backend API
- Teacher availability questions → mobile Firestore faculty collection
Each new conversation is a `ChatSession`; messages persist to
`ChatMessage`. When a session is closed/left, write a `chat_completed`
ActivityEvent. Build the mic as a visual toggle first within this
milestone to get the text flow fully working, then wire up real voice in
Milestone 9 immediately after.

### Milestone 9 — Voice input/output (core feature)
Replace the visual mic toggle with real on-device speech-to-text
(`speech_to_text` package) so the student can speak a question instead of
typing it, and text-to-speech (`flutter_tts` package) so the assistant's
reply is read back out loud. This is a required milestone, not an
add-on — don't consider Milestone 8 "done" until this is working on top of
it. **Manual step to flag:** add
`<uses-permission android:name="android.permission.RECORD_AUDIO"/>` to
`android/app/src/main/AndroidManifest.xml`, and the app must request
microphone permission at runtime on first use — if this is missing, voice
input will fail silently or crash, not just show an error.

### Milestone 10 — Chat history
List past `ChatSession`s newest-first. Tap to reopen and view full
messages (read-only replay). Multi-select or swipe to delete individual
sessions, plus a "Clear all" action with a confirmation dialog.

### Milestone 11 — Notifications
Merge backend notifications with mobile `ActivityEvent`s per the mapping
table above, sorted by time, relative timestamps ("2h ago"). Tapping a
`fee_challan_ready`/`roll_slip_ready` notification opens Milestone 3's
document viewer directly. Marking read is a real `PATCH` to the backend for
backend-sourced items; local items can just be marked read in Firestore.

### Milestone 12 — Teacher tracking
Search-by-name over the mobile Firestore `Faculty` collection (client-side
filter, not a new query per keystroke). Detail view per teacher: subjects
taught, class schedule, consultation hours, days off, email, phone, office
building + room, and a status pill. You'll need to seed a handful of
fictional faculty records here — 6-12 across the three departments feels
proportionate.

### Milestone 13 — Polish pass
Go back through every screen: consistent transitions between screens,
skeleton loaders instead of blank loading states, friendly empty states,
clear error states (e.g. no internet, backend asleep), and consistency
check on spacing/colors/iconography across all modules.

### Milestone 14 — Indoor navigation *(deferred, build last)*
2D custom-drawn campus map (`CustomPainter`, 1000×800 canvas) with
From/To pickers, buildings colored by category, and a dashed route line
through fixed walkway-hub points, exactly as in the original plan — a
flat, styled map rather than real GPS/Google Maps SDK routing, which is a
different scope entirely. Building data can be a hardcoded Dart list
rather than a Firestore collection, since it's fixed and never edited.

---

## Explicitly out of scope regardless of milestone reached

- Real LLM/GPT API integration — rule-based responder only, structured so
  a real API could be dropped in later behind a small serverless proxy
  (not built in this plan)
- Push notifications (FCM) — pull/read-based only
- Payment processing, biometric login, admissions/HR/payroll modules
- Real GPS or BLE-based indoor positioning

---

## Definition of done

- Sign up with a real seeded registration number, then log in, both work
  end to end against the live backend
- Dashboard shows real data pulled from the API, including a correctly
  calculated attendance average
- Chat responds to at least the keyword categories above and persists
  sessions you can revisit or delete
- Voice input (speech-to-text) and voice output (text-to-speech) both work
  on a real device, with microphone permission handled correctly
- Notifications show a correctly merged, correctly sorted list from both
  sources, and marking read persists
- Teacher search returns real seeded faculty with full detail
- Tapping a ready document opens the actual backend-rendered page
- The app looks and feels cohesive — no blank loading flashes, no
  unstyled error dumps
- (If reached) Indoor navigation draws a route between two selected
  buildings
