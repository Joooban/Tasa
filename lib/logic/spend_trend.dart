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
