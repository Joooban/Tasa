import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/date_utils.dart';
import 'package:tasa/logic/insights.dart';
import 'package:tasa/models/entry.dart';

void main() {
  final now = DateTime(2026, 3, 15);

  test('flavor list is sorted by frequency, most-tagged first', () {
    final entries = [
      Entry(id: '1', kind: EntryKind.home, date: now, flavors: const ['Fruity']),
      Entry(id: '2', kind: EntryKind.home, date: now, flavors: const ['Fruity', 'Nutty']),
      Entry(id: '3', kind: EntryKind.home, date: now, flavors: const ['Nutty']),
    ];
    final insights = computeInsights(entries);
    expect(insights.flavors.first.name, 'Fruity');
    expect(insights.flavors.first.count, 2);
  });

  test('best value cup ignores free or unrated entries', () {
    final entries = [
      Entry(id: '1', kind: EntryKind.home, date: now, price: 10, rating: 5, free: true),
      Entry(id: '2', kind: EntryKind.home, date: now, price: 100, rating: 0),
      Entry(id: '3', kind: EntryKind.home, date: now, price: 20, rating: 4, method: 'Chemex'),
    ];
    final insights = computeInsights(entries);
    expect(insights.bestValue?.label, 'Chemex');
  });

  test('roast trend needs at least 3 roasted entries before reporting', () {
    final entries = [
      Entry(id: '1', kind: EntryKind.home, date: now, roast: Roast.light),
      Entry(id: '2', kind: EntryKind.home, date: offsetDate(now, -1), roast: Roast.light),
    ];
    final insights = computeInsights(entries);
    expect(insights.roastedCount, 2);
  });

  test('skip entries never factor into flavor or roast insights', () {
    final entries = [Entry.skip(date: now)];
    final insights = computeInsights(entries);
    expect(insights.flavors, isEmpty);
    expect(insights.roastedCount, 0);
    expect(insights.bestValue, isNull);
  });
}
