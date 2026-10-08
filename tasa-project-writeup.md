# Tasa — Project Write-Up

*A coffee-life tracker for the Philippines, built as a real cross-platform mobile app.*

This document is the handoff spec for building Tasa in Flutter. It captures the product decisions, feature scope, architecture, and engineering standards agreed on before development starts. It is meant to be handed directly to a coding session (Claude Code) as the source of truth — not just a feature list, but the reasoning behind each call, so those decisions don't get silently reversed during implementation.

A working HTML/CSS/JS prototype already exists and is the de facto spec for every screen, interaction, and edge case below — it should be treated as the reference implementation to translate into Flutter/Dart, not a discardable sketch.

---

## 1. What Tasa Is

Tasa (Filipino for "cup") is a personal coffee habit tracker — part brew journal, part café check-in log, part spend tracker — that turns a daily ritual into a lightweight, shareable record. It's built PH-first: peso-denominated spend tracking, payday-aware framing, and a tone that treats coffee as a small daily pleasure, not a discipline problem.

**Who it's for**: people who already have some kind of coffee ritual — home brewers, café regulars, or both — and would enjoy seeing their habit reflected back to them (spend, streaks, flavor preferences) without being guilt-tripped about it.

**The retention hook**: a monthly "Wrapped" card (Spotify-Wrapped-style) that summarizes the month's coffee life and is designed to be shared — this is also the app's organic distribution mechanism.

**Core design principle carried through every feature**: gamification tracks *engagement with the app* (days logged), never *consumption* (cups drunk). Streaks, badges, and copy are written to never imply someone should drink more coffee to keep a number going. No shaming language around spend ("wasted," "overspent," "failed") — spend is reported neutrally.

---

## 2. Core Features (v1)

### Onboarding
A short first-run flow (2–3 screens) before landing on the main app:
1. What Tasa does, in one line.
2. The philosophy stated up front: streaks track showing up, not drinking more.
3. Optional name entry (for personalization — see Profile below).

Lands on the Cupboard pre-loaded with clearly-marked sample entries, which the user can dismiss/clear once they start logging real cups. This replaces the current prototype's "sample data explains itself" approach with a deliberate, intentional first impression — first-session clarity is where a niche personal app most often loses a casual tester.

### Cupboard (entry log / feed)
The core log of every cup — home-brewed or bought away. Redesigned for v1 to read like a social feed (card-based, photo-forward, scannable) rather than a plain list, since photos are now a real first-class input via native camera access (see §3) and the feed is the primary way a user "shows off" their cupboard when sharing screenshots.

Each entry: kind (Home / Away), date, brew method, price (optional/free supported), rating (bean-icon scale, not stars), caption (optional), photo (optional), time of day, flavor tags (optional), roast level (optional). Away entries carry an optional venue tag (preset categories: café / convenience / office / other) plus freeform custom venue naming — simple by default, flexible when needed.

Includes a "quick repeat" shortcut to log an entry identical to yesterday's in one tap.

### Wrapped
Monthly summary card: total cups, home/away split, spend and estimated savings from home brewing, top café, top brew method, streak info. Personalized with the user's name when set ("Jovan's month in coffee"). Exportable as a real shareable image (not just text) via native share — this is the feature most directly tied to the LinkedIn/portfolio distribution goal.

### Badges
Earned, leveled titles across multiple axes (Milestones, Home dedication, Exploration, Loyalty, Streaks, Habits, Method mastery) — replaces an earlier "personality label" concept that was rejected for going stale/inaccurate over time. All badges compute live from the entry history; nothing is frozen or recalculated on a schedule.

### Insights
Flavor profile (tag frequency), best-value cup (rating-per-peso), and roast trend (recent vs. historical roast preference) — all computed live from entries, each with a clear "not enough data yet" fallback state.

### Streaks & Rain Check
Streak = consecutive days with at least one logged entry (again: *logged*, not *consumed*). "Rain Check" (deliberately not called a "freeze" or "streak saver," to avoid importing cold/punitive imagery into a warm-coffee-themed app) is auto-earned every 7-day streak milestone and auto-consumed to bridge a single missed day. Streak detail view is tappable (Duolingo-style), showing a 7-day strip and progress toward the next streak badge.

### Profile
A local, self-entered name field — explicitly **not** authentication or an account system. No login, no password, nothing leaves the device. Used only to personalize the topbar greeting and Wrapped card text. Optional; the app works fully without it.

---

## 3. What's New for the Native Build (vs. the web prototype)

The web prototype ran entirely client-side with `localStorage` and a sandboxed environment that couldn't do real file downloads, real sharing, or real camera access. Going native removes those limitations — these become real features, not mockups:

- **Real camera/photo access.** Runtime permission requested at the moment a photo is added (not upfront at launch). If denied, the app degrades gracefully — logging still works fully without photos.
- **Photo compression.** Every photo is resized and compressed (max dimension + JPEG quality reduction) before being saved to local storage. Native local storage isn't capped like `localStorage`, but uncompressed photos accumulated daily over months will bloat app storage and slow the feed. Compress on save, not on read.
- **Real export/share.** Actual file save/share via the OS share sheet, not a copy-to-clipboard fallback. Wrapped renders as a real shareable image.
- **Real backup/restore.** A user-triggered "export to file" / "import from file" flow using the native file picker — lets someone back up their cupboard before a phone upgrade or migrate it manually to a new device. This directly addresses the biggest reliability gap of a local-only app: total data loss on uninstall or device reset.
- **Optional notifications.** A gentle, opt-in daily reminder. Not a dark-pattern nag — off by default, easy to disable, never guilt-toned.
- **Local database with schema versioning.** Replaces the JSON-blob-in-localStorage approach with a real local DB (see §5). Every schema change ships with a migration path and a pre-migration backup, so a bad migration can't silently destroy someone's history.
- **Update awareness.** Since this isn't distributed through an app store (see §6), the app checks and displays its own version, and can flag "a newer version is available" pointing back to the download link.

---

## 4. Tech Stack

- **Framework**: Flutter (Dart) — chosen over Capacitor specifically because a hybrid web-wrapper doesn't demonstrate real native cross-platform mobile development for portfolio purposes. Chosen over React Native/native-per-platform for single-codebase velocity.
- **State management**: Riverpod. Reasoning: this app has a moderate amount of shared state (entries, profile, computed stats/badges/streaks) across many screens, but no complex async/network state and no auth — Riverpod gives compile-time safety and easy testability without Bloc's boilerplate, which would be overkill at this scale.
- **Local storage**: a real local database (e.g. `sqflite` or `Hive`) rather than a flat JSON blob — needed for the schema-versioning and migration-safety requirements in §5.
- **Package ID**: `com.tasav1`
- **App display name**: Tasa (the package ID is an internal identifier only — not user-facing)

### Architecture / folder structure
Separation of concerns, not a single-file dump:
```
lib/
  models/       # Entry, Profile, Badge, etc. — plain data classes
  providers/    # Riverpod state
  services/     # DB access, image compression, notifications, backup/export
  screens/      # One file per screen
  widgets/      # Reusable UI components
  logic/        # Pure, testable functions — streak calc, badge calc, insights calc
```
Business logic (streak math, badge unlock conditions, insights computation) lives in plain, pure, testable functions separate from UI — mirroring the prototype's own `computeStats()`/`computeInsights()` pattern, which already got this separation right.

---

## 5. Data & Reliability

- **Schema-versioned local database.** Every stored record carries a schema version. Any future schema change ships with an explicit migration function — never a silent, unversioned change.
- **Pre-migration backup.** Before any migration runs, the current database is snapshotted so a failed or buggy migration can be rolled back rather than destroying the user's history.
- **User-triggered export/import.** A manual file-based backup/restore flow, independent of the app's own migration safety net — this is the user's own insurance against uninstalls, device loss, or resets.
- **No cloud sync.** Everything stays on-device. This is a deliberate privacy stance, not a missing feature (see Non-Goals).

---

## 6. Distribution & Feedback (v1)

The goal for v1 is real usage and honest feedback before spending anything on formal app store distribution.

- **Platform**: Android only for v1. iOS distribution requires either an Apple Developer account ($99/year, for TestFlight) or is blocked entirely for sideloading outside the EU's DMA-driven exception — not worth the cost until there's validated interest. iOS is a v2 decision.
- **Distribution mechanism**: a signed release APK, shared via a Google Drive link. No Play Store listing yet (deferred $25 registration until warranted by interest).
- **App signing**: a real Android release keystore is generated and used to sign the APK. This keystore must be securely backed up — losing it means any future update can't be published under the same app identity, including a later move to the Play Store.
- **Feedback loop**: an in-app "Send Feedback" action opening a `mailto:jvanmorden@gmail.com` link. No analytics, no telemetry — feedback is opt-in and human, not tracked.
- **Update awareness**: since there's no store auto-update, the app displays its version and can indicate when a newer build is available, pointing back to the same Drive link.

### Target devices
Budget and mid-range Android hardware, not flagship-only — this matches the realistic device profile of the PH market this app is built for. A conservative minimum OS floor and attention to performance on lower-spec devices (lightweight queries, compressed images) matters more here than for a flagship-first audience.

---

## 7. Engineering Standards

These exist specifically so the finished app reads as deliberately engineered, not auto-generated:

- **Tests**: unit tests on all pure logic — streak calculation, Rain Check bridging, badge unlock conditions, insights math. These are deterministic and cheap to test, and their presence is one of the clearest signals of real engineering care.
- **Linting**: `analysis_options.yaml` with strict lints enabled; code consistently run through `dart format`.
- **Null safety used properly**: no lazy force-unwraps papering over missing data.
- **Error handling**: denied permissions (camera, notifications) degrade gracefully rather than crashing; DB errors are caught and surfaced sensibly, not silently swallowed.
- **Git hygiene**: incremental commits scoped to one feature/change each, with meaningful messages — not one mega-commit dumping the whole app. This alone is one of the fastest tells when someone actually browses the repo.
- **Documentation**: a real README covering what the app is, how to run/build it, and an architecture overview.

---

## 8. Explicit Non-Goals (v1 and beyond, until reconsidered)

Written down deliberately, to prevent scope creep during development:

- No backend, no user accounts, no cloud sync.
- No "coffee twin" or any social/matching feature that would require collecting or sharing user data.
- No analytics or telemetry of any kind.
- No in-app purchases or monetization logic.
- No iOS build or distribution.

---
