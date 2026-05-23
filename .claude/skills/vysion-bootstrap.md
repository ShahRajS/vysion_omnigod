# Vysion (v2) — One-Shot Bootstrap Prompt

You are the founding engineer for **Vysion**, an accessibility-first mobile app that helps blind and low-vision users read text in front of them, hear scene descriptions, and navigate to destinations using a real-time multimodal AI co-pilot. This is a **clean-slate rebuild** in an empty repository — there is no legacy code to preserve.

## Mission

Deliver, in a single pass, both:
1. A complete, production-grade architecture document at `systemDesign/vysion_blueprint.md` (13 phases, schema below).
2. A minimal but **compiling, lint-clean, testable** Flutter scaffold that proves the architecture in `lib/`.

If you cannot complete both, output the blueprint in full and stub the scaffold; never produce a half-written blueprint.

## Authoritative Context (derived from a forensic audit of the v1 repo — treat as ground truth)

The previous codebase had three working capabilities, surrounded by aspirational scaffolding that never shipped. The rebuild keeps the working core, deletes the rest, and replaces the aspirational pieces with the modern stack below.

### What the v1 app actually did (keep these capabilities)

- **Three-mode, gesture-driven, single-screen UX**:
  - Mode 1 = Read (offline OCR via Google ML Kit `TextRecognizer`)
  - Mode 2 = Describe (streaming image → text via `flutter_gemini` calling Gemini, spoken by `flutter_tts`)
  - Mode 3 = Navigate (using gemini live)
- Gestures: swipe horizontal = change mode (with rollover); swipe down = open profile (or cancel under VoiceOver/TalkBack); tap = trigger action; double-tap = cancel; long-press = switch camera.
- A `Mutex` (from `package:mutex`) serializes (a) actions and (b) speech.
- Onboarding plays `assets/sounds/orientation.mp3` once, gated by a `SharedPreferences` `first_launch` flag.
- Firebase **Auth** + **Realtime Database** for sign-in and a single `user_data/{uid}` JSON node.

### What the v1 plan claimed but never existed (do NOT carry forward)

- ❌ No `NavigationService`, no `geocoding`, no `Geolocator` distance/bearing math.
- ❌ No `sqflite`, no `vysion_offline.db`, no `vysion_history.db`.
- ❌ No Firestore, no Cloud Storage, no `Workmanager`.
- ❌ No real Provider/MVVM wiring (the `provider` package was declared but never imported).
- ❌ No analytics, no Crashlytics.

### Bugs in v1 the rebuild MUST NOT reproduce

- Hard-coded Gemini API key in `main.dart`. **All keys live in `--dart-define` / platform secrets / Firebase Remote Config; never in source.** Treat the leaked v1 key as compromised — assume it will be revoked.
- `Firebase.initializeApp()` called without `options: DefaultFirebaseOptions.currentPlatform`.
- `import 'package:google_mlkit_text_recognition/src/text_recognizer.dart';` — never import from a package's `src/` folder.
- Settings layer that doesn't compile (orphan braces, missing imports, missing methods, in-memory "persistence").
- Two `ProfilePage` widgets and two user models (`User`, `UserData`) for the same domain entity.
- `package:http` imported without being declared in `pubspec.yaml`.
- `NSAllowsArbitraryLoads = true` in `Info.plist`.
- Empty `AndroidManifest.xml` (no `CAMERA`, `INTERNET`, `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`).
- Committing `google-services.json` and `GoogleService-Info.plist`.
- A 962-line god-widget that owns gestures, camera, AI, OCR, TTS, haptics, and routing.

## Target Stack (v2 — fresh start, debloated)

### Frontend — Flutter (latest stable, Dart >= 3.5)

- **State**: Riverpod 2 (`flutter_riverpod`) — no `provider`, no global controllers passed by constructor.
- **Routing**: `go_router` — declarative, deep-linkable, screen-reader friendly.
- **DI / service locator**: Riverpod providers only (no `get_it`).
- **Camera**: `camera` (latest).
- **OCR (offline read mode)**: `google_mlkit_text_recognition`.
- **Maps & navigation**: `google_maps_flutter` + Google **Routes API** (walking, accessible-walking preference) + **Roads API** (snap-to-path) + **Places API** (autocomplete + accessibility-vetted POIs). Use the **official Google Navigation SDK for Flutter** (`google_navigation_flutter`) for turn-by-turn.
- **Location**: `geolocator` (NOT `location`) for high-accuracy fused location and bearing.
- **Real-time AI**: Gemini Live via the Google **GenAI** SDK over WebSocket — bidirectional audio + video frames + tool use. Do not use `flutter_gemini`; the official `google_generative_ai` Dart package + a hand-rolled WebSocket client for the Live API.
- **TTS / STT**: `flutter_tts` for legacy TTS fallback; otherwise rely on Gemini Live's native audio output. STT capture goes to Gemini Live directly.
- **Haptics**: `flutter/services` (`HapticFeedback`) — drop the third-party `haptic_feedback` package.
- **Persistence**:
  - `shared_preferences` for primitive flags (theme, onboarding done, last mode).
  - `drift` (SQLite) for offline cache: OCR history, description history, recent destinations, queued telemetry. Schemas with migrations from day one.
  - Firebase Auth + Firestore for user profile, preferences sync, and accessibility preferences (NOT Realtime DB — Firestore has better querying, offline persistence, and security rules).
- **Background work**: `workmanager` for telemetry + history sync only. No background location.
- **Telemetry**: Firebase Analytics + Crashlytics.
- **Localization**: `flutter_localizations` + `.arb` files; ship en, es as day-one targets.
- **Lints**: `very_good_analysis` (stricter than `flutter_lints`).

### Backend — Node 20 (TypeScript) on Cloud Run + Firebase

A thin orchestration layer; the client talks to Gemini Live directly for low latency, but the backend handles:

- Ephemeral token minting for Gemini Live (so the client never holds a long-lived API key).
- Stripe-backed subscription verification (replaces the v1 `'backend url'` placeholder).
- Server-side Maps Platform proxying for Places API requests that need API key restrictions.
- Webhooks for Firebase Auth user creation → Firestore profile bootstrap.
- OpenAPI 3.1 spec at `backend/openapi.yaml`.

### Gemini Live Integration Spec

- **Model**: `gemini-live-2.5-flash-preview` (or current GA equivalent at build time — verify before locking).
- **Modalities**: input = audio + video frames (sampled at 1 fps when navigating, 4 fps in description mode); output = audio + text.
- **System instruction**: explicit accessibility persona ("You are Vysion, a calm, concise navigation companion for a blind user. Never use visual deixis like 'this' or 'over there'; describe positions in clock-face directions and meter distances. Warn about hazards in <300ms.").
- **Function calling**: expose these client-side tools to the model:
  - `getRoute(destination: string)` → calls Routes API
  - `searchPlaces(query: string, mode: "accessibility_vetted"|"any")` → Places API
  - `recenterMap()`, `repeatLastInstruction()`, `cancelNavigation()`
  - `setMode("read"|"describe"|"navigate")`
- **Voice activity detection**: server-side VAD only; client streams continuously while in describe/navigate mode.
- **Hazard pipeline**: a parallel low-resolution video stream (320x240 @ 2 fps) with a hazard-only system instruction; if the hazard channel emits a non-empty response, it preempts the main audio channel.

## Architecture Rules (non-negotiable)

1. No widget exceeds 250 lines. Split into smaller widgets + Riverpod providers.
2. No business logic in widgets. UI calls notifiers; notifiers call services; services hide SDKs.
3. Three layers: `lib/features/<feature>/{ui, application, domain, data}/...` with one-way deps (ui → application → domain ← data).
4. Every feature ships with: a Riverpod notifier test, a domain unit test, and one widget test using `pumpWidget` + `Semantics` matchers.
5. All user-facing strings live in `.arb` files. No hardcoded English in widgets.
6. All API keys flow through `--dart-define` and are read once at app start into a typed `AppConfig` provider; failing to provide them aborts startup with a readable error in CI.
7. **Accessibility is functional, not cosmetic**: every interactive widget has a `Semantics` label; every gesture has an explicit screen-reader equivalent action; haptic patterns are documented in code comments AND in the blueprint.
8. CI must run `dart format --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test --coverage`, and a `melos`-driven backend `npm test`. Use Flutter's official `flutter-action@v2` (or newer); pin to the `stable` channel, not a specific minor version.

## Directory Layout (target)

```
.
├── README.md
├── pubspec.yaml
├── analysis_options.yaml          # extends very_good_analysis
├── .github/workflows/ci.yml       # Flutter analyze+test, backend lint+test, OpenAPI lint
├── .gitignore                     # excludes google-services.json, GoogleService-Info.plist, .env*, *.keystore, *.jks
├── systemDesign/
│   └── vysion_blueprint.md        # the 13-phase deliverable
├── lib/
│   ├── main.dart                  # < 80 lines: bootstrap, Riverpod ProviderScope, GoRouter, FlutterError handlers
│   ├── app/
│   │   ├── app.dart               # MaterialApp.router + theme + l10n
│   │   ├── router.dart            # go_router config
│   │   ├── theme.dart
│   │   └── config/app_config.dart # typed --dart-define reader
│   ├── core/
│   │   ├── accessibility/         # haptic patterns, semantic helpers, gesture decoder
│   │   ├── ai/                    # Gemini Live client (WebSocket), function-calling registry
│   │   ├── maps/                  # Routes/Roads/Places clients
│   │   ├── storage/               # drift db, shared_prefs wrapper
│   │   ├── telemetry/             # analytics, crashlytics
│   │   └── result.dart            # sealed Result<T,E>
│   ├── features/
│   │   ├── onboarding/
│   │   ├── auth/
│   │   ├── capture/               # camera + mode switch (the v1 home screen, decomposed)
│   │   ├── read/                  # OCR mode
│   │   ├── describe/              # Gemini Live describe mode
│   │   ├── navigate/              # Routes + Nav SDK + Gemini Live tool use
│   │   ├── profile/
│   │   └── settings/              # persisted via drift, NOT in-memory
│   └── l10n/                      # app_en.arb, app_es.arb
├── backend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── openapi.yaml               # Phase 6 source of truth
│   ├── src/
│   │   ├── index.ts
│   │   ├── routes/
│   │   ├── services/gemini-token.ts
│   │   ├── services/stripe.ts
│   │   └── services/maps-proxy.ts
│   └── test/
└── test/                          # Flutter unit + widget tests
```

## Deliverable: `systemDesign/vysion_blueprint.md`

Produce a single Markdown document with all 13 phases, in this order, with no placeholders. Every phase must be concrete, citing real APIs, real schemas, real code paths.

1. **Product Overview** — vision, problem statement, primary persona (blind/low-vision adult, urban commuter), secondary personas, three core user journeys (read a sign, describe a scene, navigate to a coffee shop), success metrics (time-to-first-instruction, hazard-warning latency p95, OCR success rate, navigation completion rate).
2. **Complete UX Documentation** — screen-by-screen breakdown for capture, read, describe, navigate, onboarding, auth, profile, settings; gesture-state diagrams; sitemap; full flow diagram (Mermaid).
3. **Complete UI Documentation** — wireframes (Mermaid or ASCII), color tokens with WCAG AAA contrast pairs, typography scale supporting Dynamic Type up to 200%, design system tokens shipped as a Dart file in `lib/app/theme.dart`.
4. **Complete System Architecture** — Riverpod provider graph, three-layer feature architecture, dependency rules, directory map (the layout above), error/result types.
5. **Data Models** — Drift table definitions (Dart) for `OcrHistory`, `DescriptionHistory`, `Destinations`, `TelemetryQueue`, `UserPreferences`; Firestore document shapes for `users/{uid}`, `users/{uid}/preferences`, `users/{uid}/sessions/{sessionId}`; Firestore security rules.
6. **APIs** — full OpenAPI 3.1 YAML for the backend (`/v1/gemini/token`, `/v1/subscription/status`, `/v1/places/proxy`, `/v1/auth/webhook`); Gemini Live WebSocket message schema (setup, audio in/out, tool call, tool result); Routes API request shape we send.
7. **Accessibility Design** — TTS/STT workflow vs Gemini Live native audio decision matrix; haptic vibration pattern table (read/describe/navigate/error/cancel/hazard) with millisecond durations; gesture mapping table (sighted vs VoiceOver/TalkBack); Dynamic Type + high-contrast strategy.
8. **Infrastructure** — Firebase project config (Auth, Firestore, Crashlytics, Analytics, Remote Config), Cloud Run deployment for backend, Workmanager job catalog, drift migration policy, secrets matrix (what goes in --dart-define vs Remote Config vs Cloud Run env vs Secret Manager).
9. **Security** — auth flows (anonymous → linked email/Apple/Google), Firestore security rules walkthrough, ephemeral Gemini Live token minting flow with sequence diagram, Maps API key restrictions (HTTP referrers + bundle id + SHA-1), threat model table (camera frame leakage, location leakage, prompt injection from OCR, model jailbreak via audio, dependency CVEs), key rotation runbook.
10. **Navigation System** — Routes API request strategy (walking + accessible_walking_preference), Roads API snap-to-path on every location update, Places API autocomplete with session tokens, Navigation SDK turn-by-turn integration, **explicitly contrast against the v1 straight-line approach and explain why it was inadequate.**
11. **AI System** — Gemini Live session lifecycle (setup → bidiGenerateContent → toolCall loop → close), system instructions verbatim, tool/function-call registry (signatures + JSON schemas + client implementations), hazard channel parallel pipeline diagram, prompt-injection mitigations, fallback to non-Live Gemini for low-bandwidth networks.
12. **Rebuild Blueprint** — phase-by-phase build order (foundation → capture → read → describe → navigate → polish), file-by-file checklist for the first vertical slice (read mode), code samples for the Gemini Live WebSocket client, the Riverpod provider graph, and the drift schema.
13. **Migration Plan** — there is no v1→v2 data migration (fresh accounts), but document: rollout phases (alpha → closed beta with NFB testers → public beta → GA), feature flags via Remote Config, kill-switch strategy, observability KPIs, accessibility regression test plan with real screen-reader scripts.

## Verification (must pass before you stop)

- [ ] `systemDesign/vysion_blueprint.md` exists with all 13 phases populated; no `TODO`, no `TBD`, no `lorem ipsum`.
- [ ] `flutter pub get` succeeds.
- [ ] `dart format --set-exit-if-changed .` is a no-op.
- [ ] `flutter analyze --fatal-infos` is clean.
- [ ] `flutter test` runs at least one passing test per feature folder.
- [ ] `cd backend && npm install && npm test` is clean.
- [ ] No API keys, secrets, `google-services.json`, or `GoogleService-Info.plist` are committed; `.gitignore` excludes them and `--dart-define` is documented in the README.
- [ ] `AndroidManifest.xml` declares `CAMERA`, `INTERNET`, `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.
- [ ] `Info.plist` declares `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSSpeechRecognitionUsageDescription` — all with user-respectful copy. `NSAllowsArbitraryLoads` is **absent**.
- [ ] README documents how to run with required `--dart-define`s (`GEMINI_API_HOST`, `MAPS_API_KEY_ANDROID`, `MAPS_API_KEY_IOS`, `BACKEND_BASE_URL`).
- [ ] CI workflow runs format + analyze + test on every PR.

## Style

- Comments explain WHY, never WHAT. No narration comments.
- Every public class has a one-line dartdoc.
- No `print` — use `dart:developer` `log()`.
- No `setState` god-widgets — Riverpod or split.

Begin with Phase 1 of the blueprint. Then write the scaffold. Stop only when verification passes.
