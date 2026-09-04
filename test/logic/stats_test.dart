import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/date_utils.dart';
import 'package:tasa/logic/stats.dart';
import 'package:tasa/models/entry.dart';
import 'package:tasa/models/profile.dart';

void main() {
  final now = DateTime(2026, 3, 15);

  Entry home({required DateTime date, double? price, bool free = false}) => Entry(
        id: 'home-${date.toIso8601String()}-${price ?? 'na'}-$free',
        kind: EntryKind.home,
        date: date,
        method: 'Pour-over (V60)',
        price: price,
        free: free,
        rating: 4,
      );

  Entry away({
    required DateTime date,
    required String venueName,
    double? price,
    bool free = false,
  }) =>
      Entry(
        id: 'away-${date.toIso8601String()}-$venueName',
        kind: EntryKind.away,
        date: date,
        venueTag: VenueTag.cafe,
        venueName: venueName,
        method: 'Espresso',
        price: price,
        free: free,
        rating: 5,
      );

  test('spend counts only real entries, and a free cup costs nothing', () {
    final entries = [
      home(date: now, price: 28),
      away(date: now, venueName: 'Yardstick', price: 160, free: true),
    ];
    final stats = computeStats(entries: entries, beanProfile: const BeanProfile(), now: now);
    expect(stats.monthSpend, 28);
  });

  test('savings estimate is never negative when home brewing costs more than average away', () {
    final entries = [home(date: now, price: 500)];
    final stats = computeStats(
      entries: entries,
      beanProfile: const BeanProfile(bagPrice: 500, cupsPerBag: 1), // cpc = 500
      now: now,
    );
    expect(stats.monthSavings, 0);
  });

  test('top café is the venue with the most visits, ties broken by first-seen', () {
    final entries = [
      away(date: now, venueName: 'Yardstick', price: 160),
      away(date: offsetDate(now, -1), venueName: 'Yardstick', price: 160),
      away(date: offsetDate(now, -2), venueName: 'Wildflour', price: 175),
    ];
    final stats = computeStats(entries: entries, beanProfile: const BeanProfile(), now: now);
    expect(stats.topCafe, 'Yardstick');
    expect(stats.maxSameCafe, 2);
    expect(stats.uniqueCafes, 2);
  });

  test('entries from a different month do not count toward this month totals', () {
    final entries = [
      home(date: now, price: 28),
      home(date: DateTime(now.year, now.month - 1, 20), price: 28),
    ];
    final stats = computeStats(entries: entries, beanProfile: const BeanProfile(), now: now);
    expect(stats.monthEntryCount, 1);
  });

  test('mostlyMorning requires at least 60% of timed entries to be morning', () {
    final entries = [
      home(date: now, price: 28).copyWith(timeOfDay: DayPart.morning),
      home(date: offsetDate(now, -1), price: 28).copyWith(timeOfDay: DayPart.morning),
      home(date: offsetDate(now, -2), price: 28).copyWith(timeOfDay: DayPart.evening),
    ];
    final stats = computeStats(entries: entries, beanProfile: const BeanProfile(), now: now);
    expect(stats.mostlyMorning, isTrue);
    expect(stats.mostlyEvening, isFalse);
  });

  test('morning/afternoon/evening counts tally real entries by time of day', () {
    final entries = [
      home(date: now, price: 28).copyWith(timeOfDay: DayPart.morning),
      home(date: offsetDate(now, -1), price: 28).copyWith(timeOfDay: DayPart.morning),
      away(date: offsetDate(now, -2), venueName: 'Yardstick').copyWith(timeOfDay: DayPart.evening),
      // No time of day set — shouldn't count toward any bucket.
      home(date: offsetDate(now, -3), price: 28),
    ];
    final stats = computeStats(entries: entries, beanProfile: const BeanProfile(), now: now);
    expect(stats.morningCount, 2);
    expect(stats.eveningCount, 1);
    expect(stats.afternoonCount, 0);
  });

  test('captioned and photographed counts only include real entries with that field set', () {
    final entries = [
      home(date: now, price: 28).copyWith(caption: 'Good start'),
      home(date: offsetDate(now, -1), price: 28).copyWith(photoPath: '/tmp/a.jpg'),
      home(date: offsetDate(now, -2), price: 28), // neither
      Entry.skip(date: offsetDate(now, -3)), // skip entries never count
    ];
    final stats = computeStats(entries: entries, beanProfile: const BeanProfile(), now: now);
    expect(stats.captionedCount, 1);
    expect(stats.photographedCount, 1);
  });

  test('uniqueFlavorsCount counts distinct tags across all entries, not total tags used', () {
    final entries = [
      home(date: now, price: 28).copyWith(flavors: const ['Fruity', 'Floral']),
      home(date: offsetDate(now, -1), price: 28).copyWith(flavors: const ['Fruity', 'Ube']),
    ];
    final stats = computeStats(entries: entries, beanProfile: const BeanProfile(), now: now);
    expect(stats.uniqueFlavorsCount, 3); // Fruity, Floral, Ube — Fruity not double-counted
  });
}
