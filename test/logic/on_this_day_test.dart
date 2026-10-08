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
