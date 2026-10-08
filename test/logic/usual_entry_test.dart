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
