import '../models/entry.dart';
import '../models/profile.dart';
import 'date_utils.dart';

class StreakCounts {
  final int current;
  final int best;
  const StreakCounts({required this.current, required this.best});
}

/// Streak = consecutive days with at least one logged entry (including a "no coffee
/// today" skip) or a rain-checked date — never consecutive *cups*. Ending today or
/// yesterday (a day that hasn't been logged yet doesn't break the streak until it's over).
StreakCounts computeStreaks({
  required List<Entry> entries,
  List<DateTime> freezeDates = const [],
  DateTime? now,
}) {
  final today = todayDate(now);
  final daysWithEntry = <String>{
    for (final e in entries) e.dateIso,
    for (final d in freezeDates) isoDate(d),
  };

  var streak = 0;
  var cursor = today;
  if (!daysWithEntry.contains(isoDate(today))) {
    cursor = offsetDate(cursor, -1);
  }
  while (daysWithEntry.contains(isoDate(cursor))) {
    streak++;
    cursor = offsetDate(cursor, -1);
  }

  final allDates = daysWithEntry.toList()..sort();
  var bestStreak = 0;
  var run = 0;
  String? prev;
  for (final iso in allDates) {
    if (prev != null) {
      final diff = daysBetween(DateTime.parse(prev), DateTime.parse(iso));
      run = diff == 1 ? run + 1 : 1;
    } else {
      run = 1;
    }
    if (run > bestStreak) bestStreak = run;
    prev = iso;
  }
  bestStreak = bestStreak > streak ? bestStreak : streak;

  return StreakCounts(current: streak, best: bestStreak);
}

/// Day-by-day status for the 7-day streak strip. Mirrors the prototype's `dayStatus()`.
enum DayStatus { real, skip, freeze, none }

DayStatus dayStatusFor(DateTime date, {required List<Entry> entries, required List<DateTime> freezeDates}) {
  final iso = isoDate(date);
  final hasReal = entries.any((e) => e.kind != EntryKind.skip && e.dateIso == iso);
  if (hasReal) return DayStatus.real;
  final hasSkip = entries.any((e) => e.kind == EntryKind.skip && e.dateIso == iso);
  if (hasSkip) return DayStatus.skip;
  if (freezeDates.any((d) => isoDate(d) == iso)) return DayStatus.freeze;
  return DayStatus.none;
}

class RainCheckReconciliation {
  final AppSettings settings;
  final List<DateTime> freezeDates;
  final List<DateTime> newlyConsumedDates;
  final int milestonesAwarded;

  const RainCheckReconciliation({
    required this.settings,
    required this.freezeDates,
    required this.newlyConsumedDates,
    required this.milestonesAwarded,
  });

  bool get changed => newlyConsumedDates.isNotEmpty || milestonesAwarded > 0;
}

/// A Rain Check is auto-earned every 7-day streak milestone and auto-consumed to
/// bridge a single missed day — deliberately not called a "freeze" or "streak saver"
/// to keep the app's tone warm rather than punitive. Pure port of `reconcileFreezes()`.
RainCheckReconciliation reconcileRainChecks({
  required List<Entry> entries,
  required AppSettings settings,
  required List<DateTime> freezeDates,
  DateTime? now,
}) {
  final today = todayDate(now);
  final loggedDates = <String>{
    for (final e in entries) e.dateIso,
    for (final d in freezeDates) isoDate(d),
  };
  final allKnownIso = loggedDates.toList()..sort();
  if (allKnownIso.length < 2) {
    return RainCheckReconciliation(
      settings: settings,
      freezeDates: freezeDates,
      newlyConsumedDates: const [],
      milestonesAwarded: 0,
    );
  }

  var bank = settings.freezeBank;
  final updatedFreezeDates = List<DateTime>.from(freezeDates);
  final newlyConsumed = <DateTime>[];

  var cursor = DateTime.parse(allKnownIso.first);
  final yesterday = offsetDate(today, -1);
  var guard = 0;
  while (!cursor.isAfter(yesterday) && guard < 3650) {
    guard++;
    final iso = isoDate(cursor);
    if (!loggedDates.contains(iso) && bank > 0) {
      bank--;
      updatedFreezeDates.add(cursor);
      loggedDates.add(iso);
      newlyConsumed.add(cursor);
    }
    cursor = offsetDate(cursor, 1);
  }

  final streaks = computeStreaks(entries: entries, freezeDates: updatedFreezeDates, now: today);
  var milestone = settings.freezeMilestone;
  var milestonesAwarded = 0;
  while (streaks.best >= milestone + 7) {
    milestone += 7;
    bank += 1;
    milestonesAwarded++;
  }

  return RainCheckReconciliation(
    settings: settings.copyWith(freezeBank: bank, freezeMilestone: milestone),
    freezeDates: updatedFreezeDates,
    newlyConsumedDates: newlyConsumed,
    milestonesAwarded: milestonesAwarded,
  );
}
