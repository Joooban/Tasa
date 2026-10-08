import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/cafe_leaderboard.dart';
import 'package:tasa/models/entry.dart';

void main() {
  final now = DateTime(2026, 3, 15);
  var idCounter = 0;

  Entry cafeVisit(String name, {double? price, int rating = 0, bool free = false}) => Entry(
        id: '${name}_${idCounter++}',
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

  test('breaks a visit-count tie by higher total spend', () {
    final entries = [
      cafeVisit('Wildflour', price: 100),
      cafeVisit('Yardstick', price: 200),
    ];
    final ranking = cafeLeaderboard(entries);
    expect(ranking.first.name, 'Yardstick');
  });

  test('breaks a visit-count and spend tie alphabetically by name', () {
    final entries = [
      cafeVisit('Wildflour', price: 100),
      cafeVisit('Arcafé', price: 100),
    ];
    final ranking = cafeLeaderboard(entries);
    expect(ranking.first.name, 'Arcafé');
  });
}
