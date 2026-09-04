# Tasa

A coffee-life tracker for the Philippines — part brew journal, part café check-in log, part
spend tracker. Built PH-first: peso-denominated spend, payday-aware framing, and gamification
that rewards *showing up* (logging), never *drinking more*.

See [`tasa-project-writeup.md`](tasa-project-writeup.md) for the full product spec and the
reasoning behind each decision, and [`kape.html`](kape.html) for the original web prototype this
app is translated from.

## Download

📱 **[Download the latest APK](PASTE_GOOGLE_DRIVE_LINK_HERE)** — sideload on Android (Settings →
allow install from this source when prompted). No Play Store listing yet — see §6 of the write-up
for the distribution plan.

## Running it

Requires the Flutter SDK (stable channel) and an Android toolchain (Android Studio + SDK).

```
flutter pub get
flutter run
```

## Building a release APK

```
flutter build apk --release
```

The signed APK lands at `build/app/outputs/flutter-apk/app-release.apk`. Signing config lives in
`android/app/build.gradle.kts` / `android/key.properties` (not checked in) — see §6 of the
write-up for the distribution plan (signed APK via Drive link, no Play Store yet).

## Running tests

```
flutter test
```

Unit tests cover the pure logic in `lib/logic/` — streak calculation, Rain Check bridging,
badge unlock conditions, and insights math. These are deterministic (they take `now` as an
explicit parameter rather than reading the clock) and don't need a device or emulator.

## Architecture

```
lib/
  models/       Entry, Profile, BeanProfile, AppSettings, CoffeeStats/CoffeeInsights — plain data classes
  logic/        Pure, testable functions: streak calc, badge unlock conditions, insights,
                stats aggregation, sample data, the Wrapped joke generator — no UI, no I/O
  services/     DB access (sqflite + schema versioning + migrations), image compression,
                backup/restore, notifications, sharing, version/update checks
  providers/    Riverpod state — CupboardController is the single source of truth (mirrors
                the prototype's one `state` blob), plus derived providers for stats/insights/badges
  screens/      One file per screen/sheet
  widgets/      Reusable UI components (bean rating, entry card, wrapped card, badge cell)
  theme/        Color palette (ported 1:1 from the prototype's CSS custom properties) + ThemeData
```

Business logic never touches `BuildContext` or a database handle — it's plain functions over
plain data, which is what makes it cheap to unit test.

## Data & reliability

- SQLite via `sqflite`, with every table created at a versioned schema (`kDbSchemaVersion` in
  `database_service.dart`). A schema bump ships with an explicit migration in `_migrate()`.
- Before any migration runs, the on-disk database file is copied to `backups/` so a bad
  migration can be rolled back rather than silently destroying entry history.
- Settings → "Your data" gives the user their own manual export/import to a JSON file via the
  native file picker, independent of the migration safety net.
- Everything is local-only. No backend, no accounts, no analytics.
