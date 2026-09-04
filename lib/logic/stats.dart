import '../models/entry.dart';
import '../models/profile.dart';
import '../models/stats.dart';
import 'constants.dart';
import 'date_utils.dart';
import 'streak.dart';

List<Entry> realEntries(List<Entry> entries) =>
    entries.where((e) => e.kind != EntryKind.skip).toList();

/// Pure port of the prototype's `computeStats()`. Takes `now` and `freezeDates`
/// explicitly so behavior is fully deterministic and unit-testable.
CoffeeStats computeStats({
  required List<Entry> entries,
  required BeanProfile beanProfile,
  List<DateTime> freezeDates = const [],
  DateTime? now,
}) {
  final today = todayDate(now);
  final real = realEntries(entries);
  final thisMonthKey = monthKey(today);

  bool inThisMonth(Entry e) => monthKey(e.date) == thisMonthKey;
  final monthReal = real.where(inThisMonth).toList();

  final totalCups = real.length;
  final homeCount = real.where((e) => e.kind == EntryKind.home).length;
  final awayCount = real.where((e) => e.kind == EntryKind.away).length;

  final monthHome = monthReal.where((e) => e.kind == EntryKind.home).toList();
  final monthAway = monthReal.where((e) => e.kind == EntryKind.away).toList();

  double spendOf(List<Entry> list) =>
      list.fold(0.0, (a, e) => a + (e.free ? 0 : (e.price ?? 0)));
  final monthHomeSpend = spendOf(monthHome);
  final monthAwaySpend = spendOf(monthAway);
  final monthSpend = monthHomeSpend + monthAwaySpend;

  final awayPrices = real
      .where((e) => e.kind == EntryKind.away && !e.free && (e.price ?? 0) > 0)
      .map((e) => e.price!)
      .toList();
  final avgAway = awayPrices.isNotEmpty
      ? awayPrices.reduce((a, b) => a + b) / awayPrices.length
      : kFallbackAwayPrice;

  final cpc = beanProfile.costPerCup;
  double avgHomeCost;
  if (cpc != null) {
    avgHomeCost = cpc;
  } else {
    final homeWithPrice =
        real.where((e) => e.kind == EntryKind.home && (e.price ?? 0) > 0).toList();
    avgHomeCost = homeWithPrice.isNotEmpty
        ? homeWithPrice.fold(0.0, (a, e) => a + e.price!) / homeWithPrice.length
        : 28;
  }
  final priceDelta = avgAway - avgHomeCost;
  final monthSavings = (priceDelta > 0 ? priceDelta : 0.0) * monthHome.length;

  final cafeCounts = <String, int>{};
  for (final e in real) {
    if (e.kind == EntryKind.away && e.venueTag == VenueTag.cafe && (e.venueName ?? '').isNotEmpty) {
      cafeCounts[e.venueName!] = (cafeCounts[e.venueName!] ?? 0) + 1;
    }
  }
  String? topCafe;
  var maxSameCafe = 0;
  cafeCounts.forEach((k, v) {
    if (v > maxSameCafe) {
      maxSameCafe = v;
      topCafe = k;
    }
  });
  final uniqueCafes = cafeCounts.length;

  final methodCounts = <String, int>{};
  for (final e in real) {
    final m = e.method ?? 'Other';
    methodCounts[m] = (methodCounts[m] ?? 0) + 1;
  }
  String? topMethod;
  var topMethodCount = 0;
  methodCounts.forEach((k, v) {
    if (v > topMethodCount) {
      topMethodCount = v;
      topMethod = k;
    }
  });
  final uniqueMethods = methodCounts.length;
  final uniqueListedMethods =
      methodCounts.keys.where((m) => kBrewMethods.contains(m)).length;

  final streaks = computeStreaks(entries: entries, freezeDates: freezeDates, now: today);
  final streak = streaks.current;
  final bestStreak = streaks.best;

  final homeRatioThisMonth =
      monthReal.isNotEmpty ? monthHome.length / monthReal.length : 0.0;
  final tod = {'morning': 0, 'afternoon': 0, 'evening': 0};
  for (final e in real) {
    if (e.timeOfDay != null) {
      tod[e.timeOfDay!.id] = (tod[e.timeOfDay!.id] ?? 0) + 1;
    }
  }
  final todTotal = tod['morning']! + tod['afternoon']! + tod['evening']!;
  final mostlyMorning = todTotal > 0 && tod['morning']! / todTotal >= 0.6;
  final mostlyEvening = todTotal > 0 && tod['evening']! / todTotal >= 0.6;

  final captionedCount = real.where((e) => (e.caption ?? '').isNotEmpty).length;
  final photographedCount = real.where((e) => e.photoPath != null).length;
  final uniqueFlavorsCount = real.expand((e) => e.flavors).toSet().length;

  return CoffeeStats(
    totalCups: totalCups,
    homeCount: homeCount,
    awayCount: awayCount,
    monthSpend: monthSpend,
    monthHomeSpend: monthHomeSpend,
    monthAwaySpend: monthAwaySpend,
    monthSavings: monthSavings,
    topCafe: topCafe,
    maxSameCafe: maxSameCafe,
    uniqueCafes: uniqueCafes,
    topMethod: topMethod,
    uniqueMethods: uniqueMethods,
    uniqueListedMethods: uniqueListedMethods,
    methodCounts: methodCounts,
    streak: streak,
    bestStreak: bestStreak,
    homeRatioThisMonth: homeRatioThisMonth,
    mostlyMorning: mostlyMorning,
    mostlyEvening: mostlyEvening,
    monthEntryCount: monthReal.length,
    monthHomeCount: monthHome.length,
    monthAwayCount: monthAway.length,
    morningCount: tod['morning']!,
    afternoonCount: tod['afternoon']!,
    eveningCount: tod['evening']!,
    captionedCount: captionedCount,
    photographedCount: photographedCount,
    uniqueFlavorsCount: uniqueFlavorsCount,
  );
}
