# Seven-Feature Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add seven user-facing features to the Tasa Flutter app — "On this day" memories, a "Log my usual" quick-repeat, a configurable daily-reminder time, single-cup sharing, Year Wrapped, a multi-month spend trend chart, and a café leaderboard.

**Architecture:** Every feature follows the codebase's existing layering: a pure, unit-tested function in `lib/logic/`, wired through a Riverpod provider in `lib/providers/derived_providers.dart` (or a new `CupboardController` method for anything that mutates state), surfaced in `lib/screens/` or `lib/widgets/`. No feature introduces a backend call, a new third-party dependency, or touches the local-only storage model — all data for every feature is derived live from entries already in SQLite.

**Tech Stack:** Flutter/Dart, Riverpod (`AsyncNotifier` + `Provider`), `sqflite`, `flutter_test` for logic-layer unit tests, manual live verification on the Android emulator for UI (this codebase has no widget-test suite — only `lib/logic/` is unit-tested; UI correctness has been verified by live emulator testing all session, and this plan follows that established pattern rather than introducing a new one).

**Spec:** No separate spec document — derived directly from conversation: the user asked for (1) "On this day" resurfacing, (2) "Log my usual" quick-repeat, (3) configurable daily-reminder time, (4) share-a-single-cup, (5) Year Wrapped, (6) multi-month spend trend view, (7) a café leaderboard screen, explicitly scoped to "from On this day to café leaderboard only" (excludes the previously-discussed "scheduled local auto-backups" idea).

## Global Constraints

- No new pubspec dependencies — every feature is buildable with what's already installed (Flutter SDK, Riverpod, sqflite, intl, share_plus).
- No network calls, no analytics, no new permissions — stays inside the existing "nothing leaves this device" architecture.
- Any `AppSettings` field addition requires a DB schema bump (`kDbSchemaVersion` in `lib/services/database_service.dart`) with an explicit migration in `_migrate()` — never a silent column add.
- Any new field added to `CoffeeStats` (`lib/models/stats.dart`) must be optional with a default value, not `required` — `test/logic/badges_test.dart` constructs `CoffeeStats(...)` directly by hand and would break on a new required field.
- Match existing copy tone: gentle, no guilt, no exclamation-point hype (see `lib/screens/settings_screen.dart`'s "never guilt-toned" framing).
- `flutter analyze` must be clean and `flutter test` must pass (all pre-existing + new tests) after every task.

## Review Focus

- **Fewer than 3 real entries exist** ("Log my usual") — the app must say so gently and not suggest a template built from a single coincidental cup or from sample data.
- **A brand-new cupboard with only today's sample entries** ("On this day") — must show nothing, not a false memory built from `isSample: true` rows.
- **The reminder is re-enabled after being off** (configurable time) — the previously-saved hour/minute must still be respected, not silently reset to the 9:00am default.
- **Sharing a cup with no photo** (share-a-single-cup) — `_NoPhotoHero`'s gradient banner must still capture correctly via `RepaintBoundary`, not produce a blank/transparent image.
- **A December entry when viewing "this year" in January** (Year Wrapped / spend trend) — year and month boundaries must use calendar year/month, not a rolling 365/30-day window, and the spend-trend chart must correctly cross a Dec→Jan boundary without miscounting.

---

### Task 1: "On this day" memory banner

**Files:**
- Create: `lib/logic/on_this_day.dart`
- Create: `test/logic/on_this_day_test.dart`
- Create: `lib/widgets/on_this_day_banner.dart`
- Modify: `lib/providers/derived_providers.dart` — add `onThisDayProvider`
- Modify: `lib/screens/cupboard_screen.dart` — render the banner above the entry list

**Interfaces:**
- Produces: `List<Entry> onThisDay(List<Entry> entries, {DateTime? now})` — real, non-sample entries matching today's month+day from an earlier year, most-recent-year first.
- Produces: `onThisDayProvider` (`Provider<List<Entry>>`) in `derived_providers.dart`, consumed by `cupboard_screen.dart`.
- Produces: `OnThisDayBanner({required List<Entry> memories, required ValueChanged<Entry> onTap})` widget.

- [ ] **Step 1: Write the failing test**

Create `test/logic/on_this_day_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/on_this_day.dart';
import 'package:tasa/models/entry.dart';

void main() {
  final today = DateTime(2026, 3, 15);

  Entry entry({required DateTime date, bool isSample = false, EntryKind kind = EntryKind.home}) =>
      Entry(id: date.toIso8601String(), kind: kind, date: date, isSample: isSample);

  test('matches the same month/day in an earlier year', () {
    final entries = [entry(date: DateTime(2025, 3, 15))];
    expect(onThisDay(entries, now: today).length, 1);
  });

  test('ignores a different day entirely', () {
    final entries = [entry(date: DateTime(2025, 3, 16))];
    expect(onThisDay(entries, now: today), isEmpty);
  });

  test('ignores sample entries', () {
    final entries = [entry(date: DateTime(2025, 3, 15), isSample: true)];
    expect(onThisDay(entries, now: today), isEmpty);
  });

  test('ignores skip entries', () {
    final entries = [entry(date: DateTime(2025, 3, 15), kind: EntryKind.skip)];
    expect(onThisDay(entries, now: today), isEmpty);
  });

  test('ignores this same year — not a memory yet', () {
    final entries = [entry(date: DateTime(2026, 3, 15))];
    expect(onThisDay(entries, now: today), isEmpty);
  });

  test('multiple matching years sort most-recent first', () {
    final entries = [
      entry(date: DateTime(2023, 3, 15)),
      entry(date: DateTime(2025, 3, 15)),
      entry(date: DateTime(2024, 3, 15)),
    ];
    final result = onThisDay(entries, now: today);
    expect(result.map((e) => e.date.year).toList(), [2025, 2024, 2023]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/logic/on_this_day_test.dart`
Expected: FAIL — `on_this_day.dart` doesn't exist yet (import error).

- [ ] **Step 3: Write the implementation**

Create `lib/logic/on_this_day.dart`:
```dart
import '../models/entry.dart';

/// Real (non-sample, non-skip) entries logged on this exact calendar date in
/// a previous year — "On this day" memories, most-recent-year first.
List<Entry> onThisDay(List<Entry> entries, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final matches = entries
      .where((e) =>
          e.kind != EntryKind.skip &&
          !e.isSample &&
          e.date.year < today.year &&
          e.date.month == today.month &&
          e.date.day == today.day)
      .toList();
  matches.sort((a, b) => b.date.compareTo(a.date));
  return matches;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/logic/on_this_day_test.dart`
Expected: PASS — 6/6 tests green.

- [ ] **Step 5: Add the provider**

In `lib/providers/derived_providers.dart`, add the import `import '../logic/on_this_day.dart';` alongside the other `logic/` imports, and add after `venueNamesProvider`:
```dart
/// Real entries from exactly this calendar date in an earlier year.
final onThisDayProvider = Provider<List<Entry>>((ref) {
  final s = ref.watch(cupboardControllerProvider).valueOrNull;
  if (s == null) return const [];
  return onThisDay(s.entries);
});
```

- [ ] **Step 6: Write the banner widget**

Create `lib/widgets/on_this_day_banner.dart`:
```dart
import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../models/entry.dart';
import '../theme/app_colors.dart';
import 'bean_icon.dart';

/// A single resurfaced memory at the top of the feed — "On this day" from a
/// past year. Dismissible for the current viewing only (resets next app
/// open); nothing is persisted, so it never silently disappears forever.
class OnThisDayBanner extends StatefulWidget {
  final List<Entry> memories;
  final ValueChanged<Entry> onTap;

  const OnThisDayBanner({super.key, required this.memories, required this.onTap});

  @override
  State<OnThisDayBanner> createState() => _OnThisDayBannerState();
}

class _OnThisDayBannerState extends State<OnThisDayBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || widget.memories.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final memory = widget.memories.first;
    final yearsAgo = DateTime.now().year - memory.date.year;
    final yearsLabel = yearsAgo == 1 ? '1 year ago' : '$yearsAgo years ago';
    final title = memory.kind == EntryKind.home
        ? (memory.method ?? 'Home brew')
        : (memory.venueName ?? 'Away');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.amber.withValues(alpha: 0.12),
        border: Border.all(color: c.amber.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () => widget.onTap(memory),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            BeanIcon(size: 28, color: c.amberInk),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('On this day, $yearsLabel',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: c.amberInk)),
                  const SizedBox(height: 2),
                  Text('$title · ${fmtShortDate(memory.date)}',
                      style: TextStyle(fontSize: 13, color: c.ink)),
                  if (widget.memories.length > 1)
                    Text('+${widget.memories.length - 1} more year(s)',
                        style: TextStyle(fontSize: 11, color: c.inkFaint)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: c.inkFaint),
              onPressed: () => setState(() => _dismissed = true),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Wire into the Cupboard feed**

In `lib/screens/cupboard_screen.dart`, add imports:
```dart
import '../widgets/on_this_day_banner.dart';
```
(`entry_detail_screen.dart` is already imported.)

Immediately after the existing `SliverToBoxAdapter` that holds the filter chips/action buttons (ends at the line `const SliverToBoxAdapter(child: SizedBox(height: 100)),` is the LAST sliver — insert this new one right after the filter/actions `SliverToBoxAdapter` and before the `if (entries.isEmpty)` block):
```dart
SliverToBoxAdapter(
  child: OnThisDayBanner(
    memories: ref.watch(onThisDayProvider),
    onTap: (e) => Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: e.id)),
    ),
  ),
),
```

- [ ] **Step 8: Run the full test suite**

Run: `flutter analyze && flutter test`
Expected: clean analyze, all tests (old + 6 new) pass.

- [ ] **Step 9: Live-verify on the emulator**

1. `flutter build apk --debug`, install, launch.
2. Edit an existing real entry's date (via the entry form's Date picker) to exactly one year before today.
3. Return to the Cupboard tab — confirm the amber "On this day, 1 year ago" banner appears above the feed with that entry's method/venue and date.
4. Tap the banner — confirm it opens that entry's detail screen.
5. Tap the "×" — confirm the banner disappears for the rest of this session.
6. Screenshot both states (banner visible, banner dismissed).

- [ ] **Step 10: Commit**

```bash
git add lib/logic/on_this_day.dart test/logic/on_this_day_test.dart lib/widgets/on_this_day_banner.dart lib/providers/derived_providers.dart lib/screens/cupboard_screen.dart
git commit -m "$(cat <<'EOF'
feat: add "On this day" memory banner to the Cupboard feed

Resurfaces a real (non-sample) cup logged on today's calendar date in
an earlier year, with a session-local dismiss.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: "Log my usual" quick-repeat

**Files:**
- Create: `lib/logic/usual_entry.dart`
- Create: `test/logic/usual_entry_test.dart`
- Modify: `lib/providers/cupboard_controller.dart` — add `logUsual()`
- Modify: `lib/screens/cupboard_screen.dart` — add the button

**Interfaces:**
- Consumes: nothing new — operates on `List<Entry>` already in `CupboardState.entries`.
- Produces: `Entry? usualEntry(List<Entry> entries)` — the real entry whose (kind, method, venueName) combo is most frequent, ties broken by most recent; `null` with fewer than 3 real entries.
- Produces: `CupboardController.logUsual()` → `Future<String>`, following the exact pattern of `repeatYesterday()`/`skipToday()` (clone as new, save, return a status message).

- [ ] **Step 1: Write the failing test**

Create `test/logic/usual_entry_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/usual_entry.dart';
import 'package:tasa/models/entry.dart';

void main() {
  Entry home(DateTime date, String method) => Entry(
        id: '${date.toIso8601String()}-$method',
        kind: EntryKind.home,
        date: date,
        method: method,
      );

  test('returns null with fewer than 3 real entries', () {
    final entries = [home(DateTime(2026, 1, 1), 'Pour-over (V60)')];
    expect(usualEntry(entries), isNull);
  });

  test('returns the most frequently logged method/kind combo', () {
    final entries = [
      home(DateTime(2026, 1, 1), 'Pour-over (V60)'),
      home(DateTime(2026, 1, 2), 'Pour-over (V60)'),
      home(DateTime(2026, 1, 3), 'Espresso'),
    ];
    expect(usualEntry(entries)?.method, 'Pour-over (V60)');
  });

  test('breaks ties by most recently logged', () {
    final entries = [
      home(DateTime(2026, 1, 1), 'Pour-over (V60)'),
      home(DateTime(2026, 1, 5), 'Espresso'),
      home(DateTime(2026, 1, 10), 'Chemex'),
    ];
    expect(usualEntry(entries)?.method, 'Chemex');
  });

  test('ignores sample and skip entries toward the 3-entry minimum', () {
    final entries = [
      home(DateTime(2026, 1, 1), 'Pour-over (V60)'),
      Entry(
        id: 's1',
        kind: EntryKind.home,
        date: DateTime(2026, 1, 2),
        method: 'Pour-over (V60)',
        isSample: true,
      ),
      Entry(
        id: 's2',
        kind: EntryKind.home,
        date: DateTime(2026, 1, 3),
        method: 'Pour-over (V60)',
        isSample: true,
      ),
    ];
    expect(usualEntry(entries), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/logic/usual_entry_test.dart`
Expected: FAIL — `usual_entry.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/logic/usual_entry.dart`:
```dart
import '../models/entry.dart';

/// The entry whose (kind, method, venueName) combination appears most often
/// among real entries — used as a one-tap "log my usual" template. Returns
/// null with fewer than 3 real entries, so a brand-new cupboard doesn't
/// suggest a "usual" built from a single coincidental cup.
Entry? usualEntry(List<Entry> entries) {
  final real = entries.where((e) => e.kind != EntryKind.skip && !e.isSample).toList();
  if (real.length < 3) return null;

  String keyOf(Entry e) => '${e.kind.name}|${e.method ?? ''}|${e.venueName ?? ''}';
  final counts = <String, int>{};
  final mostRecentByKey = <String, Entry>{};
  for (final e in real) {
    final k = keyOf(e);
    counts[k] = (counts[k] ?? 0) + 1;
    final current = mostRecentByKey[k];
    if (current == null || e.date.isAfter(current.date)) {
      mostRecentByKey[k] = e;
    }
  }
  final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
  final tiedKeys = counts.entries.where((e) => e.value == maxCount).map((e) => e.key);

  Entry? best;
  for (final k in tiedKeys) {
    final candidate = mostRecentByKey[k]!;
    if (best == null || candidate.date.isAfter(best.date)) best = candidate;
  }
  return best;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/logic/usual_entry_test.dart`
Expected: PASS — 4/4 tests green.

- [ ] **Step 5: Add the controller method**

In `lib/providers/cupboard_controller.dart`, add the import `import '../logic/usual_entry.dart';` and add this method right after `repeatYesterday()`:
```dart
Future<String> logUsual() async {
  final usual = usualEntry(_current.entries);
  if (usual == null) {
    return 'Log a few more cups first, then your usual will show up here.';
  }
  final copy = usual.copyWith(
    id: Entry.newId(),
    date: todayDate(),
    isSample: false,
  );
  await saveEntry(copy, isNew: true);
  final label = copy.kind == EntryKind.home ? copy.method : copy.venueName;
  return 'Logged your usual — ${label ?? 'cup'}.';
}
```

- [ ] **Step 6: Wire the button**

In `lib/screens/cupboard_screen.dart`, in the second `Row` (the one with "Repeat yesterday" / "No coffee today"), add a third button after "No coffee today":
```dart
const SizedBox(width: 8),
OutlinedButton(
  onPressed: () async {
    final msg = await ref.read(cupboardControllerProvider.notifier).logUsual();
    if (context.mounted) _toast(context, msg);
  },
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  child: const Text('Log my usual', style: TextStyle(fontSize: 12.5)),
),
```

- [ ] **Step 7: Run the full test suite**

Run: `flutter analyze && flutter test`
Expected: clean analyze, all tests pass.

- [ ] **Step 8: Live-verify on the emulator**

1. `flutter build apk --debug`, install, launch.
2. Log 3 real "Pour-over (V60)" home entries on different days (or confirm sample data already provides enough repetition — sample data has 2 Pour-over (V60) entries, so log one more real one to cross the 3-entry threshold with Pour-over as the clear majority among *real* entries).
3. Tap "Log my usual" — confirm a toast like "Logged your usual — Pour-over (V60)." appears and a new today-dated entry shows up at the top of the feed.
4. With fewer than 3 real entries (fresh install, samples only), tap "Log my usual" and confirm the gentle "Log a few more cups first…" message instead of a crash or a sample-based entry.
5. Screenshot the success case.

- [ ] **Step 9: Commit**

```bash
git add lib/logic/usual_entry.dart test/logic/usual_entry_test.dart lib/providers/cupboard_controller.dart lib/screens/cupboard_screen.dart
git commit -m "$(cat <<'EOF'
feat: add "Log my usual" one-tap quick-repeat

Clones whichever (kind, method, venue) combination is logged most
often among real entries, ties broken by most recent — mirrors the
existing "Repeat yesterday" action's save/toast pattern.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Configurable daily-reminder time

**Files:**
- Modify: `lib/models/profile.dart` — add `reminderHour`/`reminderMinute` to `AppSettings`
- Modify: `lib/services/database_service.dart` — bump schema version, add migration
- Modify: `lib/providers/cupboard_controller.dart` — add `setReminderTime()`
- Modify: `lib/screens/settings_screen.dart` — add the time-picker row

**Interfaces:**
- Produces: `AppSettings.reminderHour` (`int`, default `9`), `AppSettings.reminderMinute` (`int`, default `0`).
- Produces: `CupboardController.setReminderTime(int hour, int minute)` → `Future<void>`.
- Consumes: `NotificationService.scheduleDailyReminder({int hour = 9, int minute = 0})` — already exists in `lib/services/notification_service.dart`, unchanged.

- [ ] **Step 1: Add the settings fields**

In `lib/models/profile.dart`, modify the `AppSettings` class:
```dart
class AppSettings {
  final bool hideAmount;
  final bool seenRealEntry;
  final int freezeBank;
  final int freezeMilestone;
  final bool notificationsEnabled;
  final bool hasOnboarded;
  final AppThemeMode themeMode;
  final int reminderHour;
  final int reminderMinute;

  const AppSettings({
    this.hideAmount = false,
    this.seenRealEntry = false,
    this.freezeBank = 0,
    this.freezeMilestone = 0,
    this.notificationsEnabled = false,
    this.hasOnboarded = false,
    this.themeMode = AppThemeMode.system,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  AppSettings copyWith({
    bool? hideAmount,
    bool? seenRealEntry,
    int? freezeBank,
    int? freezeMilestone,
    bool? notificationsEnabled,
    bool? hasOnboarded,
    AppThemeMode? themeMode,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      AppSettings(
        hideAmount: hideAmount ?? this.hideAmount,
        seenRealEntry: seenRealEntry ?? this.seenRealEntry,
        freezeBank: freezeBank ?? this.freezeBank,
        freezeMilestone: freezeMilestone ?? this.freezeMilestone,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        hasOnboarded: hasOnboarded ?? this.hasOnboarded,
        themeMode: themeMode ?? this.themeMode,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );

  Map<String, Object?> toMap() => {
        'id': 1,
        'hide_amount': hideAmount ? 1 : 0,
        'seen_real_entry': seenRealEntry ? 1 : 0,
        'freeze_bank': freezeBank,
        'freeze_milestone': freezeMilestone,
        'notifications_enabled': notificationsEnabled ? 1 : 0,
        'has_onboarded': hasOnboarded ? 1 : 0,
        'theme_mode': themeMode.id,
        'reminder_hour': reminderHour,
        'reminder_minute': reminderMinute,
      };

  factory AppSettings.fromMap(Map<String, Object?> m) => AppSettings(
        hideAmount: (m['hide_amount'] as int? ?? 0) == 1,
        seenRealEntry: (m['seen_real_entry'] as int? ?? 0) == 1,
        freezeBank: m['freeze_bank'] as int? ?? 0,
        freezeMilestone: m['freeze_milestone'] as int? ?? 0,
        notificationsEnabled: (m['notifications_enabled'] as int? ?? 0) == 1,
        hasOnboarded: (m['has_onboarded'] as int? ?? 0) == 1,
        themeMode: AppThemeModeX.fromId(m['theme_mode'] as String?),
        reminderHour: m['reminder_hour'] as int? ?? 9,
        reminderMinute: m['reminder_minute'] as int? ?? 0,
      );
}
```

- [ ] **Step 2: Bump the schema and add the migration**

In `lib/services/database_service.dart`:
1. Change `const kDbSchemaVersion = 3;` to `const kDbSchemaVersion = 4;`
2. In `_createAll()`'s `app_settings` table SQL, add two columns before the closing `)`:
```sql
        theme_mode TEXT NOT NULL DEFAULT 'system',
        reminder_hour INTEGER NOT NULL DEFAULT 9,
        reminder_minute INTEGER NOT NULL DEFAULT 0
```
3. In `_migrate()`, add:
```dart
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN reminder_hour INTEGER NOT NULL DEFAULT 9',
      );
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN reminder_minute INTEGER NOT NULL DEFAULT 0',
      );
    }
```

- [ ] **Step 3: Add the controller method**

In `lib/providers/cupboard_controller.dart`, add after `setNotificationsEnabled`:
```dart
Future<void> setReminderTime(int hour, int minute) async {
  final settings = _current.settings.copyWith(reminderHour: hour, reminderMinute: minute);
  final db = ref.read(databaseServiceProvider);
  await db.saveAppSettings(settings);
  state = AsyncData(_current.copyWith(settings: settings));
}
```

- [ ] **Step 4: Wire the Settings UI**

In `lib/screens/settings_screen.dart`, replace the "Daily reminder" panel's `child:` (the `Material(type: MaterialType.transparency, child: SwitchListTile(...))` block) with:
```dart
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                SwitchListTile(
                  value: state.settings.notificationsEnabled,
                  onChanged: (v) async {
                    final notifier = ref.read(cupboardControllerProvider.notifier);
                    if (v) {
                      bool granted;
                      try {
                        granted = await ref.read(notificationServiceProvider).requestPermission();
                      } catch (_) {
                        granted = false;
                      }
                      if (!granted) {
                        if (context.mounted) {
                          _toast(context,
                              "Notifications weren't allowed — you can turn this on later from system settings.");
                        }
                        return;
                      }
                    }
                    try {
                      if (v) {
                        await ref.read(notificationServiceProvider).scheduleDailyReminder(
                              hour: state.settings.reminderHour,
                              minute: state.settings.reminderMinute,
                            );
                      } else {
                        await ref.read(notificationServiceProvider).cancelDailyReminder();
                      }
                    } catch (_) {
                      if (context.mounted) {
                        _toast(context,
                            "Saved, but couldn't reach the system notification service — try again if reminders don't behave.");
                      }
                    }
                    await notifier.setNotificationsEnabled(v);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remind me once a day', style: TextStyle(fontSize: 13.5)),
                ),
                if (state.settings.notificationsEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminder time', style: TextStyle(fontSize: 13.5)),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: state.settings.reminderHour,
                            minute: state.settings.reminderMinute,
                          ),
                        );
                        if (picked == null) return;
                        await ref
                            .read(cupboardControllerProvider.notifier)
                            .setReminderTime(picked.hour, picked.minute);
                        try {
                          await ref
                              .read(notificationServiceProvider)
                              .scheduleDailyReminder(hour: picked.hour, minute: picked.minute);
                        } catch (_) {
                          if (context.mounted) {
                            _toast(context, "Saved, but couldn't reach the system notification service.");
                          }
                        }
                      },
                      child: Text(
                        TimeOfDay(
                          hour: state.settings.reminderHour,
                          minute: state.settings.reminderMinute,
                        ).format(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
```

- [ ] **Step 5: Run the full test suite**

Run: `flutter analyze && flutter test`
Expected: clean analyze, all tests pass (no existing test constructs `AppSettings` positionally in a way that would break from new optional fields).

- [ ] **Step 6: Live-verify on the emulator**

1. `flutter build apk --debug`, install, launch.
2. Settings → enable "Remind me once a day" (grant the permission prompt) — confirm a new "Reminder time" row appears showing "9:00 AM".
3. Tap it, pick a different time (e.g. 7:30 PM), confirm the row updates to show "7:30 PM".
4. Force-stop and relaunch the app — confirm the time is still "7:30 PM" (persisted, not reset).
5. Turn the switch off — confirm the "Reminder time" row disappears.
6. Screenshot the enabled state with a custom time set.

- [ ] **Step 7: Commit**

```bash
git add lib/models/profile.dart lib/services/database_service.dart lib/providers/cupboard_controller.dart lib/screens/settings_screen.dart
git commit -m "$(cat <<'EOF'
feat: make the daily reminder time configurable

AppSettings gains reminderHour/reminderMinute (DB schema v3->v4,
default 9:00am, explicit migration). Settings now shows a time picker
under the reminder toggle instead of a hardcoded 9am.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Share a single cup

**Files:**
- Modify: `lib/services/share_service.dart` — generalize into a reusable `shareImage()`
- Modify: `lib/screens/entry_detail_screen.dart` — capture + share the card

**Interfaces:**
- Produces: `ShareService.shareImage({required GlobalKey boundaryKey, required String fallbackText, required String subject})` → `Future<void>`.
- `ShareService.shareWrappedCard(...)` keeps its exact existing signature and behavior (delegates internally to `shareImage`) — `lib/screens/wrapped_screen.dart`'s call site needs no change.

- [ ] **Step 1: Generalize `ShareService`**

Replace the full contents of `lib/services/share_service.dart`:
```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Real OS share sheet — the native build's replacement for the prototype's
/// clipboard/`navigator.share` fallback. Any shared card renders as an
/// actual image captured from the on-screen widget via its RepaintBoundary.
class ShareService {
  Future<void> shareWrappedCard({
    required GlobalKey boundaryKey,
    required String fallbackText,
  }) =>
      shareImage(boundaryKey: boundaryKey, fallbackText: fallbackText, subject: 'My Tasa Wrapped');

  Future<void> shareImage({
    required GlobalKey boundaryKey,
    required String fallbackText,
    required String subject,
  }) async {
    final bytes = await _captureBoundary(boundaryKey);
    if (bytes == null) {
      await SharePlus.instance.share(
        ShareParams(text: fallbackText, subject: subject),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'tasa-share-${DateTime.now().microsecondsSinceEpoch}.png');
    final file = File(path);
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: fallbackText, subject: subject),
    );
  }

  Future<Uint8List?> _captureBoundary(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
```

- [ ] **Step 2: Run analyze to confirm `wrapped_screen.dart` still compiles unchanged**

Run: `flutter analyze`
Expected: clean — `shareWrappedCard(boundaryKey:, fallbackText:)` call site in `wrapped_screen.dart` is untouched and still matches the (unchanged) signature.

- [ ] **Step 3: Convert `EntryDetailScreen` to capture + share**

Replace the full contents of `lib/screens/entry_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entry.dart';
import '../providers/cupboard_controller.dart';
import '../providers/services_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/delete_with_undo.dart';
import '../widgets/entry_card.dart';
import 'entry_form_sheet.dart';

/// A single cup, shown full-page like an opened social post — reached by
/// tapping a card in the feed. Editing/deleting live behind the card's own
/// triple-dot menu here too, so this screen and the feed behave identically.
/// The share action captures the same card as a shareable PNG, reusing the
/// Wrapped screen's RepaintBoundary-capture pattern.
class EntryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;
  const EntryDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entries = ref.watch(cupboardControllerProvider).valueOrNull?.entries;
    final entry = entries?.where((e) => e.id == widget.entryId).firstOrNull;

    // Deleted (including via this screen's own menu) while we're looking at it.
    if (entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return Scaffold(backgroundColor: c.bg, body: const SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: const Text('Cup'),
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            onPressed: _sharing ? null : () => _share(entry),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _boundaryKey,
          child: EntryCard(
            entry: entry,
            onEdit: () => showEntryForm(context, existing: entry),
            // No explicit pop here — deleting flips `entry` to null above on the
            // next rebuild, which already pops. A second pop call racing that
            // one (mid exit-transition) is exactly the kind of thing that trips
            // Navigator/Element assertions, so there's deliberately only one path.
            onDelete: () => deleteEntryWithUndo(context, ref, entry.id),
          ),
        ),
      ),
    );
  }

  Future<void> _share(Entry entry) async {
    setState(() => _sharing = true);
    final title = entry.kind == EntryKind.home
        ? (entry.method ?? 'Home brew')
        : (entry.venueName ?? 'Away');
    try {
      await ref.read(shareServiceProvider).shareImage(
            boundaryKey: _boundaryKey,
            fallbackText: '$title, logged on Tasa ☕',
            subject: 'A cup from Tasa',
          );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
```

- [ ] **Step 4: Run the full test suite**

Run: `flutter analyze && flutter test`
Expected: clean analyze, all tests pass.

- [ ] **Step 5: Live-verify on the emulator**

1. `flutter build apk --debug`, install, launch.
2. Open a cup **with** a photo from the feed, tap the new share icon in the app bar — confirm the native share sheet opens with an image attachment.
3. Open a cup **without** a photo (shows the `_NoPhotoHero` gradient banner), tap share — confirm the captured image includes that gradient banner correctly (not blank/transparent — this is the Review Focus item for this task).
4. Screenshot the share sheet appearing for both cases.

- [ ] **Step 6: Commit**

```bash
git add lib/services/share_service.dart lib/screens/entry_detail_screen.dart
git commit -m "$(cat <<'EOF'
feat: share a single cup from its detail screen

Generalizes ShareService into a reusable shareImage() (shareWrappedCard
now delegates to it, unchanged behavior) and adds a share action to
EntryDetailScreen's app bar using the same RepaintBoundary-capture
pattern already proven for Wrapped.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Year Wrapped

**Files:**
- Modify: `lib/models/stats.dart` — add optional year-scoped fields to `CoffeeStats`
- Modify: `lib/logic/stats.dart` — compute the new fields in `computeStats()`
- Modify: `test/logic/stats_test.dart` — add a year-totals test
- Modify: `lib/widgets/wrapped_card.dart` — add an `isYear` display mode
- Modify: `lib/screens/wrapped_screen.dart` — add a Month/Year toggle

**Interfaces:**
- Produces on `CoffeeStats` (all optional, default `0`): `yearSpend`, `yearHomeSpend`, `yearAwaySpend`, `yearSavings` (`double`); `yearEntryCount`, `yearHomeCount`, `yearAwayCount` (`int`).
- Produces: `WrappedCard(..., bool isYear = false)` — unchanged default behavior when omitted.

- [ ] **Step 1: Write the failing test**

In `test/logic/stats_test.dart`, add a new test (inside the existing `void main() { ... }`, alongside the other `test(...)` calls, using the file's existing `home()`/`away()` helpers already defined there):
```dart
  test('year totals only include entries from the current calendar year', () {
    final entries = [
      home(date: DateTime(2026, 1, 10), price: 50),
      home(date: DateTime(2025, 12, 20), price: 999), // last year — excluded
    ];
    final stats = computeStats(
      entries: entries,
      beanProfile: const BeanProfile(),
      now: DateTime(2026, 3, 15),
    );
    expect(stats.yearEntryCount, 1);
    expect(stats.yearSpend, 50);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/logic/stats_test.dart`
Expected: FAIL — `yearEntryCount`/`yearSpend` don't exist on `CoffeeStats` yet (compile error).

- [ ] **Step 3: Add the fields to `CoffeeStats`**

In `lib/models/stats.dart`, add to the `CoffeeStats` class (fields, constructor params — all with defaults so `test/logic/badges_test.dart`'s direct `CoffeeStats(...)` construction keeps compiling unchanged):
```dart
  final double yearSpend;
  final double yearHomeSpend;
  final double yearAwaySpend;
  final double yearSavings;
  final int yearEntryCount;
  final int yearHomeCount;
  final int yearAwayCount;
```
and in the constructor:
```dart
    this.yearSpend = 0,
    this.yearHomeSpend = 0,
    this.yearAwaySpend = 0,
    this.yearSavings = 0,
    this.yearEntryCount = 0,
    this.yearHomeCount = 0,
    this.yearAwayCount = 0,
```
(Add these as the last entries before the closing `});` of the constructor — after `required this.uniqueFlavorsCount,`. Note they use `this.x = default` not `required this.x`, which is valid Dart even interleaved with `required` params earlier in the same constructor.)

- [ ] **Step 4: Compute the fields in `computeStats()`**

In `lib/logic/stats.dart`, immediately after the existing block that computes `monthHomeSpend`/`monthAwaySpend`/`monthSpend` (right after `final monthSpend = monthHomeSpend + monthAwaySpend;`), add:
```dart
  final thisYear = today.year;
  bool inThisYear(Entry e) => e.date.year == thisYear;
  final yearReal = real.where(inThisYear).toList();
  final yearHome = yearReal.where((e) => e.kind == EntryKind.home).toList();
  final yearAway = yearReal.where((e) => e.kind == EntryKind.away).toList();
  final yearHomeSpend = spendOf(yearHome);
  final yearAwaySpend = spendOf(yearAway);
  final yearSpend = yearHomeSpend + yearAwaySpend;
```
Then, after the existing `final monthSavings = (priceDelta > 0 ? priceDelta : 0.0) * monthHome.length;` line, add:
```dart
  final yearSavings = (priceDelta > 0 ? priceDelta : 0.0) * yearHome.length;
```
Finally, in the `return CoffeeStats(...)` call at the bottom, add after `uniqueFlavorsCount: uniqueFlavorsCount,`:
```dart
    yearSpend: yearSpend,
    yearHomeSpend: yearHomeSpend,
    yearAwaySpend: yearAwaySpend,
    yearSavings: yearSavings,
    yearEntryCount: yearReal.length,
    yearHomeCount: yearHome.length,
    yearAwayCount: yearAway.length,
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/logic/stats_test.dart`
Expected: PASS — including the new year-totals test.

- [ ] **Step 6: Add the `isYear` mode to `WrappedCard`**

In `lib/widgets/wrapped_card.dart`:
1. Add `final bool isYear;` to the field list and `this.isYear = false,` to the constructor.
2. At the top of `build()`, after `final name = (profileName ?? '').trim();`, add:
```dart
    final periodWord = isYear ? 'year' : 'month';
    final spend = isYear ? stats.yearSpend : stats.monthSpend;
    final savings = isYear ? stats.yearSavings : stats.monthSavings;
    final entryCount = isYear ? stats.yearEntryCount : stats.monthEntryCount;
    final homeCount = isYear ? stats.yearHomeCount : stats.monthHomeCount;
    final awayCount = isYear ? stats.yearAwayCount : stats.monthAwayCount;
```
3. Change `final amountText = hideAmount ? '₱•••' : peso(stats.monthSpend);` to `final amountText = hideAmount ? '₱•••' : peso(spend);`
4. Change `final joke = hideAmount ? null : jokeFor(stats.monthSpend, jokeSeed);` to `final joke = hideAmount ? null : jokeFor(spend, jokeSeed);`
5. Change the title `Text(name.isNotEmpty ? "$name's month in coffee" : 'Your month in coffee', ...)` to:
```dart
            name.isNotEmpty ? "$name's $periodWord in coffee" : 'Your $periodWord in coffee',
```
6. Change the six `_row(...)` calls that currently read:
```dart
          _row('Cups this month', '${stats.monthEntryCount}', onEspresso),
          _row('Home-brewed', '${stats.monthHomeCount}', onEspresso),
          _row('Away', '${stats.monthAwayCount}', onEspresso),
          _row('Est. saved brewing at home', hideAmount ? '₱•••' : peso(stats.monthSavings), onEspresso),
```
to:
```dart
          _row('Cups this $periodWord', '$entryCount', onEspresso),
          _row('Home-brewed', '$homeCount', onEspresso),
          _row('Away', '$awayCount', onEspresso),
          _row('Est. saved brewing at home', hideAmount ? '₱•••' : peso(savings), onEspresso),
```
(The `Top café` / `Go-to method` / `Longest streak` rows are unchanged — those stats are already computed all-time in `computeStats()`, not month-scoped.)

- [ ] **Step 7: Add the Month/Year toggle to `WrappedScreen`**

In `lib/screens/wrapped_screen.dart`:
1. Add this enum above the `WrappedScreen` class:
```dart
enum _WrappedPeriod { month, year }
```
2. Add `_WrappedPeriod _period = _WrappedPeriod.month;` as a field on `_WrappedScreenState`, alongside `_boundaryKey`/`_sharing`.
3. At the top of `build()`, after the existing null-checks, add:
```dart
    final isYear = _period == _WrappedPeriod.year;
```
4. As the very first child of the `ListView`'s `children:` list (before the existing `Row` that shows `fmtMonthYear(DateTime.now())`), insert:
```dart
        Center(
          child: SegmentedButton<_WrappedPeriod>(
            segments: const [
              ButtonSegment(value: _WrappedPeriod.month, label: Text('Month')),
              ButtonSegment(value: _WrappedPeriod.year, label: Text('Year')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
        ),
        const SizedBox(height: 8),
```
5. Change the existing month/year header `Text` from `fmtMonthYear(DateTime.now())` to:
```dart
            Text(
              isYear ? DateTime.now().year.toString() : fmtMonthYear(DateTime.now()),
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c.inkSoft),
            ),
```
6. In the `WrappedCard(...)` constructor call, add `isYear: isYear,` as the last argument.
7. In `_share()`, replace the body computing `lines` with:
```dart
    final isYear = _period == _WrappedPeriod.year;
    final spend = isYear ? stats.yearSpend : stats.monthSpend;
    final entryCount = isYear ? stats.yearEntryCount : stats.monthEntryCount;
    final homeCount = isYear ? stats.yearHomeCount : stats.monthHomeCount;
    final awayCount = isYear ? stats.yearAwayCount : stats.monthAwayCount;
    final periodWord = isYear ? 'year' : 'month';
    final lines = [
      name.isNotEmpty ? "$name's coffee $periodWord on Tasa ☕" : 'My coffee $periodWord on Tasa ☕',
      hide ? 'Spend: kept private' : 'Spend: ${peso(spend)}',
      'Cups: $entryCount ($homeCount home, $awayCount away)',
      if (stats.topCafe != null) 'Top café: ${stats.topCafe}',
      if (stats.topMethod != null) 'Go-to method: ${stats.topMethod}',
      'Longest streak: ${stats.bestStreak} days',
    ];
```
(This replaces the old hardcoded `'Spend: ...'`/`'Cups: ${stats.monthEntryCount} (...)'` lines — same structure, period-aware values.)

- [ ] **Step 8: Run the full test suite**

Run: `flutter analyze && flutter test`
Expected: clean analyze, all tests pass.

- [ ] **Step 9: Live-verify on the emulator**

1. `flutter build apk --debug`, install, launch.
2. Open the Wrapped tab — confirm the Month/Year segmented control appears above the existing month label, defaulted to "Month", behaving exactly as before.
3. Tap "Year" — confirm the header changes to just the year number (e.g. "2026"), the card retitles to "Your year in coffee", and the numbers shown are year-scoped (sample data is all within the current month, so year and month totals should currently match — that's expected and correct, not a bug).
4. Tap "Share" while in Year mode — confirm the share sheet opens with year-scoped fallback text.
5. Screenshot both Month and Year states.

- [ ] **Step 10: Commit**

```bash
git add lib/models/stats.dart lib/logic/stats.dart test/logic/stats_test.dart lib/widgets/wrapped_card.dart lib/screens/wrapped_screen.dart
git commit -m "$(cat <<'EOF'
feat: add Year Wrapped alongside the existing Month view

CoffeeStats gains optional year-scoped fields (yearSpend, yearEntryCount,
etc.) computed the same way as the existing month fields. WrappedCard
and WrappedScreen take a Month/Year toggle; sharing respects whichever
period is selected.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Multi-month spend trend chart

**Files:**
- Create: `lib/logic/spend_trend.dart`
- Create: `test/logic/spend_trend_test.dart`
- Create: `lib/widgets/spend_trend_chart.dart`
- Modify: `lib/providers/derived_providers.dart` — add `spendTrendProvider`
- Modify: `lib/screens/wrapped_screen.dart` — add the chart section

**Interfaces:**
- Produces: `class MonthSpend { final DateTime month; final double spend; }` and `List<MonthSpend> monthlySpendTrend(List<Entry> entries, {int months = 6, DateTime? now})`, oldest month first.
- Produces: `spendTrendProvider` (`Provider<List<MonthSpend>>`).
- Produces: `SpendTrendChart({required List<MonthSpend> months})` widget.

- [ ] **Step 1: Write the failing test**

Create `test/logic/spend_trend_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/spend_trend.dart';
import 'package:tasa/models/entry.dart';

void main() {
  final now = DateTime(2026, 3, 15);

  Entry home(DateTime date, double price) => Entry(
        id: '${date.toIso8601String()}-$price',
        kind: EntryKind.home,
        date: date,
        price: price,
      );

  test('returns the requested number of months, oldest first', () {
    final trend = monthlySpendTrend([], months: 3, now: now);
    expect(trend.length, 3);
    expect(trend.first.month, DateTime(2026, 1, 1));
    expect(trend.last.month, DateTime(2026, 3, 1));
  });

  test('sums spend per month and excludes other months', () {
    final entries = [
      home(DateTime(2026, 3, 1), 50),
      home(DateTime(2026, 3, 20), 30),
      home(DateTime(2026, 2, 5), 100),
    ];
    final trend = monthlySpendTrend(entries, months: 3, now: now);
    expect(trend[2].spend, 80); // March
    expect(trend[1].spend, 100); // February
    expect(trend[0].spend, 0); // January
  });

  test('a free cup contributes nothing to spend', () {
    final entries = [
      Entry(id: '1', kind: EntryKind.home, date: now, price: 100, free: true),
    ];
    final trend = monthlySpendTrend(entries, months: 1, now: now);
    expect(trend.single.spend, 0);
  });

  test('crosses a year boundary correctly', () {
    final entries = [home(DateTime(2025, 12, 10), 40)];
    final trend = monthlySpendTrend(entries, months: 4, now: now); // Dec..Mar
    expect(trend.first.month, DateTime(2025, 12, 1));
    expect(trend.first.spend, 40);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/logic/spend_trend_test.dart`
Expected: FAIL — `spend_trend.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/logic/spend_trend.dart`:
```dart
import '../models/entry.dart';
import 'date_utils.dart';
import 'stats.dart';

class MonthSpend {
  final DateTime month;
  final double spend;
  const MonthSpend({required this.month, required this.spend});
}

/// Per-month spend for the last [months] months (including the current
/// one), oldest first — the data behind the Wrapped screen's spend-trend
/// chart. Dart's DateTime constructor correctly rolls month=0 back into
/// December of the previous year, so this walks across year boundaries
/// without special-casing.
List<MonthSpend> monthlySpendTrend(
  List<Entry> entries, {
  int months = 6,
  DateTime? now,
}) {
  final today = todayDate(now);
  final real = realEntries(entries);
  final result = <MonthSpend>[];
  for (var i = months - 1; i >= 0; i--) {
    final monthDate = DateTime(today.year, today.month - i, 1);
    final key = monthKey(monthDate);
    final spend = real
        .where((e) => monthKey(e.date) == key)
        .fold(0.0, (a, e) => a + (e.free ? 0 : (e.price ?? 0)));
    result.add(MonthSpend(month: monthDate, spend: spend));
  }
  return result;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/logic/spend_trend_test.dart`
Expected: PASS — 4/4 tests green.

- [ ] **Step 5: Add the provider**

In `lib/providers/derived_providers.dart`, add the import `import '../logic/spend_trend.dart';` and add after `onThisDayProvider` (from Task 1):
```dart
final spendTrendProvider = Provider<List<MonthSpend>>((ref) {
  final s = ref.watch(cupboardControllerProvider).valueOrNull;
  if (s == null) return const [];
  return monthlySpendTrend(s.entries);
});
```

- [ ] **Step 6: Write the chart widget**

Create `lib/widgets/spend_trend_chart.dart`:
```dart
import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../logic/spend_trend.dart';
import '../theme/app_colors.dart';

/// A minimal, dependency-free bar chart — consistent with the rest of the
/// app's hand-rolled visuals (BeanIcon, StreakIcon) rather than pulling in
/// a charting package for one simple view.
class SpendTrendChart extends StatelessWidget {
  final List<MonthSpend> months;

  const SpendTrendChart({super.key, required this.months});

  static const _barAreaHeight = 90.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxSpend = months.fold<double>(0, (a, m) => m.spend > a ? m.spend : a);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: months.map((m) {
          final barHeight = maxSpend > 0
              ? (m.spend / maxSpend * _barAreaHeight).clamp(3.0, _barAreaHeight)
              : 3.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (m.spend > 0)
                  Text(peso(m.spend), style: TextStyle(fontSize: 9, color: c.inkFaint)),
                const SizedBox(height: 4),
                Container(
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: c.amber,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_monthLabel(m.month), style: TextStyle(fontSize: 10, color: c.inkSoft)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _monthLabel(DateTime d) =>
      const ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][d.month - 1];
}
```

- [ ] **Step 7: Wire into `WrappedScreen`**

In `lib/screens/wrapped_screen.dart`, add imports:
```dart
import '../widgets/spend_trend_chart.dart';
```
After the closing `),` of the "YOUR COFFEE PROFILE" `Container` (i.e. right before the final `],` that closes the `ListView`'s `children:` list), add:
```dart
        const SizedBox(height: 24),
        Text('SPEND, LAST 6 MONTHS',
            style: TextStyle(
                fontSize: 13, letterSpacing: 1, color: c.inkSoft, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: SpendTrendChart(months: ref.watch(spendTrendProvider)),
        ),
```

- [ ] **Step 8: Run the full test suite**

Run: `flutter analyze && flutter test`
Expected: clean analyze, all tests pass.

- [ ] **Step 9: Live-verify on the emulator**

1. `flutter build apk --debug`, install, launch.
2. Open the Wrapped tab, scroll to the bottom — confirm a "SPEND, LAST 6 MONTHS" section with a 6-bar chart renders, current month's bar showing a non-zero amount from sample/real data, other months showing flat/zero bars.
3. Confirm no layout overflow (check for the red/yellow overflow stripes Flutter shows in debug mode).
4. Screenshot the chart.

- [ ] **Step 10: Commit**

```bash
git add lib/logic/spend_trend.dart test/logic/spend_trend_test.dart lib/widgets/spend_trend_chart.dart lib/providers/derived_providers.dart lib/screens/wrapped_screen.dart
git commit -m "$(cat <<'EOF'
feat: add a 6-month spend trend chart to Wrapped

Hand-rolled bar chart (no new charting dependency) showing per-month
spend for the last 6 months, correctly crossing year boundaries via
Dart's own DateTime month-overflow normalization.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Café leaderboard

**Files:**
- Create: `lib/logic/cafe_leaderboard.dart`
- Create: `test/logic/cafe_leaderboard_test.dart`
- Create: `lib/screens/cafe_leaderboard_screen.dart`
- Modify: `lib/screens/wrapped_screen.dart` — add the entry point

**Interfaces:**
- Produces: `class CafeRanking { final String name; final int visitCount; final double totalSpend; final double avgRating; }` and `List<CafeRanking> cafeLeaderboard(List<Entry> entries)`, most-visited first.
- Produces: `CafeLeaderboardScreen` — a standalone pushed screen, no constructor params.

- [ ] **Step 1: Write the failing test**

Create `test/logic/cafe_leaderboard_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/cafe_leaderboard.dart';
import 'package:tasa/models/entry.dart';

void main() {
  final now = DateTime(2026, 3, 15);
  var _idCounter = 0;

  Entry cafeVisit(String name, {double? price, int rating = 0, bool free = false}) => Entry(
        id: '${name}_${_idCounter++}',
        kind: EntryKind.away,
        date: now,
        venueTag: VenueTag.cafe,
        venueName: name,
        price: price,
        rating: rating,
        free: free,
      );

  test('ranks cafés by visit count, most-visited first', () {
    final entries = [cafeVisit('Yardstick'), cafeVisit('Yardstick'), cafeVisit('Wildflour')];
    final ranking = cafeLeaderboard(entries);
    expect(ranking.first.name, 'Yardstick');
    expect(ranking.first.visitCount, 2);
  });

  test('sums total spend per café, excluding free visits', () {
    final entries = [
      cafeVisit('Yardstick', price: 150),
      cafeVisit('Yardstick', price: 100, free: true),
    ];
    final ranking = cafeLeaderboard(entries);
    expect(ranking.single.totalSpend, 150);
  });

  test('averages only rated visits', () {
    final entries = [
      cafeVisit('Yardstick', rating: 4),
      cafeVisit('Yardstick', rating: 2),
      cafeVisit('Yardstick', rating: 0),
    ];
    final ranking = cafeLeaderboard(entries);
    expect(ranking.single.avgRating, 3.0);
  });

  test('ignores non-café away entries and home entries', () {
    final entries = [
      Entry(
        id: '1',
        kind: EntryKind.away,
        date: now,
        venueTag: VenueTag.office,
        venueName: 'Office pantry',
      ),
      Entry(id: '2', kind: EntryKind.home, date: now, method: 'Pour-over (V60)'),
    ];
    expect(cafeLeaderboard(entries), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/logic/cafe_leaderboard_test.dart`
Expected: FAIL — `cafe_leaderboard.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/logic/cafe_leaderboard.dart`:
```dart
import '../models/entry.dart';
import 'stats.dart';

class CafeRanking {
  final String name;
  final int visitCount;
  final double totalSpend;
  final double avgRating;
  const CafeRanking({
    required this.name,
    required this.visitCount,
    required this.totalSpend,
    required this.avgRating,
  });
}

/// Every café visited, ranked by visit count (most-visited first) — the
/// full picture behind the single "top café" stat shown elsewhere.
List<CafeRanking> cafeLeaderboard(List<Entry> entries) {
  final real = realEntries(entries).where((e) =>
      e.kind == EntryKind.away &&
      e.venueTag == VenueTag.cafe &&
      (e.venueName ?? '').isNotEmpty);

  final byName = <String, List<Entry>>{};
  for (final e in real) {
    byName.putIfAbsent(e.venueName!, () => []).add(e);
  }

  final rankings = byName.entries.map((entry) {
    final visits = entry.value;
    final spend = visits.fold(0.0, (a, e) => a + (e.free ? 0 : (e.price ?? 0)));
    final ratedVisits = visits.where((e) => e.rating > 0).toList();
    final avgRating = ratedVisits.isNotEmpty
        ? ratedVisits.fold(0, (a, e) => a + e.rating) / ratedVisits.length
        : 0.0;
    return CafeRanking(
      name: entry.key,
      visitCount: visits.length,
      totalSpend: spend,
      avgRating: avgRating.toDouble(),
    );
  }).toList();

  rankings.sort((a, b) => b.visitCount.compareTo(a.visitCount));
  return rankings;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/logic/cafe_leaderboard_test.dart`
Expected: PASS — 4/4 tests green.

- [ ] **Step 5: Write the leaderboard screen**

Create `lib/screens/cafe_leaderboard_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/cafe_leaderboard.dart';
import '../logic/format.dart';
import '../providers/cupboard_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/bean_icon.dart';

/// The full café ranking behind the single "Top café" line shown in
/// Wrapped — every place visited, most-visited first.
class CafeLeaderboardScreen extends ConsumerWidget {
  const CafeLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final entries = ref.watch(cupboardControllerProvider).valueOrNull?.entries ?? const [];
    final ranking = cafeLeaderboard(entries);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(backgroundColor: c.bg, elevation: 0, title: const Text('Café leaderboard')),
      body: ranking.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Log a few café visits and your leaderboard will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.inkSoft),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ranking.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = ranking[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: c.clay.withValues(alpha: 0.18), shape: BoxShape.circle),
                        child: Text('${i + 1}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: c.clayInk)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(
                              '${r.visitCount} visit${r.visitCount == 1 ? '' : 's'} · ${peso(r.totalSpend)} total',
                              style: TextStyle(fontSize: 12, color: c.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      if (r.avgRating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BeanIcon(size: 14, color: c.amber),
                            const SizedBox(width: 3),
                            Text(r.avgRating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink)),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 6: Wire the entry point into `WrappedScreen`**

In `lib/screens/wrapped_screen.dart`, add import:
```dart
import 'cafe_leaderboard_screen.dart';
```
Immediately after the existing "Share" button's `Center(child: ElevatedButton.icon(...))` block (and before the `const SizedBox(height: 24),` that precedes "YOUR COFFEE PROFILE"), insert:
```dart
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const CafeLeaderboardScreen()),
            ),
            child: const Text('See full café leaderboard →'),
          ),
        ),
```

- [ ] **Step 7: Run the full test suite**

Run: `flutter analyze && flutter test`
Expected: clean analyze, all tests pass.

- [ ] **Step 8: Live-verify on the emulator**

1. `flutter build apk --debug`, install, launch.
2. Open the Wrapped tab, tap "See full café leaderboard →".
3. Confirm the ranked list appears with "Yardstick Coffee" at #1 (sample data has 2 Yardstick Coffee visits vs. 1 Wildflour Café visit), each row showing visit count, total spend, and average rating.
4. Back out, confirm no crash/overflow.
5. Screenshot the leaderboard.

- [ ] **Step 9: Commit**

```bash
git add lib/logic/cafe_leaderboard.dart test/logic/cafe_leaderboard_test.dart lib/screens/cafe_leaderboard_screen.dart lib/screens/wrapped_screen.dart
git commit -m "$(cat <<'EOF'
feat: add a full café leaderboard screen

Ranks every café by visit count with total spend and average rating,
reachable from Wrapped — the full picture behind the existing single
"top café" stat.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Final Pass (after all 7 tasks)

- [ ] Run `flutter analyze && flutter test` once more across the whole branch — confirm zero issues, all tests (37 pre-existing + ~22 new) pass.
- [ ] Full live walkthrough on the emulator touching all 7 features in one session (not just immediately after each task) to catch any cross-feature interaction issues.
- [ ] Rebuild the release APK (`flutter build apk --release --split-per-abi`) and confirm it still builds clean with the new code.
