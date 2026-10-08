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
