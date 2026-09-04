import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/date_utils.dart';
import 'package:tasa/logic/streak.dart';
import 'package:tasa/models/entry.dart';
import 'package:tasa/models/profile.dart';

Entry _entryOn(DateTime date, {EntryKind kind = EntryKind.home}) => Entry(
      id: 'e-${date.toIso8601String()}-$kind',
      kind: kind,
      date: date,
      method: kind == EntryKind.home ? 'Pour-over (V60)' : null,
      rating: 3,
    );

void main() {
  final now = DateTime(2026, 3, 15);

  group('computeStreaks', () {
    test('is zero with no entries', () {
      final result = computeStreaks(entries: const [], now: now);
      expect(result.current, 0);
      expect(result.best, 0);
    });

    test('counts consecutive days ending today', () {
      final entries = [
        _entryOn(offsetDate(now, 0)),
        _entryOn(offsetDate(now, -1)),
        _entryOn(offsetDate(now, -2)),
      ];
      final result = computeStreaks(entries: entries, now: now);
      expect(result.current, 3);
      expect(result.best, 3);
    });

    test('still counts an active streak when today has not been logged yet', () {
      final entries = [
        _entryOn(offsetDate(now, -1)),
        _entryOn(offsetDate(now, -2)),
      ];
      final result = computeStreaks(entries: entries, now: now);
      expect(result.current, 2);
    });

    test('breaks on a gap day', () {
      final entries = [
        _entryOn(offsetDate(now, 0)),
        _entryOn(offsetDate(now, -1)),
        // gap at -2
        _entryOn(offsetDate(now, -3)),
      ];
      final result = computeStreaks(entries: entries, now: now);
      expect(result.current, 2);
    });

    test('a skip entry keeps the streak alive without implying consumption', () {
      final entries = [
        _entryOn(offsetDate(now, 0)),
        Entry.skip(date: offsetDate(now, -1)),
        _entryOn(offsetDate(now, -2)),
      ];
      final result = computeStreaks(entries: entries, now: now);
      expect(result.current, 3);
    });

    test('best streak can exceed the current streak', () {
      final entries = [
        _entryOn(offsetDate(now, 0)),
        // an older, longer run further back
        _entryOn(offsetDate(now, -10)),
        _entryOn(offsetDate(now, -11)),
        _entryOn(offsetDate(now, -12)),
        _entryOn(offsetDate(now, -13)),
      ];
      final result = computeStreaks(entries: entries, now: now);
      expect(result.current, 1);
      expect(result.best, 4);
    });

    test('a rain-checked date bridges the streak like a logged day', () {
      final entries = [
        _entryOn(offsetDate(now, 0)),
        // -1 missed, but bridged by a freeze date
        _entryOn(offsetDate(now, -2)),
      ];
      final result = computeStreaks(
        entries: entries,
        freezeDates: [offsetDate(now, -1)],
        now: now,
      );
      expect(result.current, 3);
    });
  });

  group('reconcileRainChecks', () {
    test('does nothing with fewer than two known dates', () {
      final result = reconcileRainChecks(
        entries: [_entryOn(now)],
        settings: const AppSettings(freezeBank: 2),
        freezeDates: const [],
        now: now,
      );
      expect(result.changed, isFalse);
    });

    test('consumes a rain check to bridge a single missed day', () {
      final entries = [
        _entryOn(offsetDate(now, 0)),
        _entryOn(offsetDate(now, -2)), // -1 is missed
      ];
      final result = reconcileRainChecks(
        entries: entries,
        settings: const AppSettings(freezeBank: 1),
        freezeDates: const [],
        now: now,
      );
      expect(result.newlyConsumedDates, [offsetDate(now, -1)]);
      expect(result.settings.freezeBank, 0);
    });

    test('does not consume a rain check when the bank is empty', () {
      final entries = [
        _entryOn(offsetDate(now, 0)),
        _entryOn(offsetDate(now, -2)),
      ];
      final result = reconcileRainChecks(
        entries: entries,
        settings: const AppSettings(freezeBank: 0),
        freezeDates: const [],
        now: now,
      );
      expect(result.newlyConsumedDates, isEmpty);
    });

    test('awards a rain check once the best streak crosses a 7-day milestone', () {
      final entries = List.generate(7, (i) => _entryOn(offsetDate(now, -i)));
      final result = reconcileRainChecks(
        entries: entries,
        settings: const AppSettings(freezeBank: 0, freezeMilestone: 0),
        freezeDates: const [],
        now: now,
      );
      expect(result.milestonesAwarded, 1);
      expect(result.settings.freezeBank, 1);
      expect(result.settings.freezeMilestone, 7);
    });
  });

  group('dayStatusFor', () {
    test('reports real for a logged day', () {
      final status = dayStatusFor(now, entries: [_entryOn(now)], freezeDates: const []);
      expect(status, DayStatus.real);
    });

    test('reports skip for a skip entry', () {
      final status =
          dayStatusFor(now, entries: [Entry.skip(date: now)], freezeDates: const []);
      expect(status, DayStatus.skip);
    });

    test('reports freeze for a rain-checked day with no entry', () {
      final status = dayStatusFor(now, entries: const [], freezeDates: [now]);
      expect(status, DayStatus.freeze);
    });

    test('reports none for an untouched day', () {
      final status = dayStatusFor(now, entries: const [], freezeDates: const []);
      expect(status, DayStatus.none);
    });
  });
}
