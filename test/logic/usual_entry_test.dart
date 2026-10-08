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

  group('repeatableUsualCopy', () {
    final source = Entry(
      id: 'old-id',
      kind: EntryKind.home,
      date: DateTime(2026, 1, 1),
      method: 'Pour-over (V60)',
      price: 28,
      free: true,
      rating: 5,
      caption: 'first cup at the new place',
      notes: 'tasted amazing',
      photoPath: '/tmp/old-photo.jpg',
      flavors: const ['Floral'],
    );

    test('gives the copy a new id, the target date, and clears isSample', () {
      final copy = repeatableUsualCopy(source, date: DateTime(2026, 3, 15));
      expect(copy.id, isNot('old-id'));
      expect(copy.date, DateTime(2026, 3, 15));
      expect(copy.isSample, isFalse);
    });

    test('clears the photo, caption, notes, rating, and free flag', () {
      final copy = repeatableUsualCopy(source, date: DateTime(2026, 3, 15));
      expect(copy.photoPath, isNull);
      expect(copy.caption, isNull);
      expect(copy.notes, isNull);
      expect(copy.rating, 0);
      expect(copy.free, isFalse);
    });

    test('keeps the kind, method, price, and flavors', () {
      final copy = repeatableUsualCopy(source, date: DateTime(2026, 3, 15));
      expect(copy.kind, EntryKind.home);
      expect(copy.method, 'Pour-over (V60)');
      expect(copy.price, 28);
      expect(copy.flavors, const ['Floral']);
    });
  });
}
