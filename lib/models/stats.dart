/// Aggregate numbers computed live from entry history — never stored, never cached.
class CoffeeStats {
  final int totalCups;
  final int homeCount;
  final int awayCount;
  final double monthSpend;
  final double monthHomeSpend;
  final double monthAwaySpend;
  final double monthSavings;
  final String? topCafe;
  final int maxSameCafe;
  final int uniqueCafes;
  final String? topMethod;
  final int uniqueMethods;
  final int uniqueListedMethods;
  final Map<String, int> methodCounts;
  final int streak;
  final int bestStreak;
  final double homeRatioThisMonth;
  final bool mostlyMorning;
  final bool mostlyEvening;
  final int monthEntryCount;
  final int monthHomeCount;
  final int monthAwayCount;
  final int morningCount;
  final int afternoonCount;
  final int eveningCount;
  final int captionedCount;
  final int photographedCount;
  final int uniqueFlavorsCount;

  const CoffeeStats({
    required this.totalCups,
    required this.homeCount,
    required this.awayCount,
    required this.monthSpend,
    required this.monthHomeSpend,
    required this.monthAwaySpend,
    required this.monthSavings,
    required this.topCafe,
    required this.maxSameCafe,
    required this.uniqueCafes,
    required this.topMethod,
    required this.uniqueMethods,
    required this.uniqueListedMethods,
    required this.methodCounts,
    required this.streak,
    required this.bestStreak,
    required this.homeRatioThisMonth,
    required this.mostlyMorning,
    required this.mostlyEvening,
    required this.monthEntryCount,
    required this.monthHomeCount,
    required this.monthAwayCount,
    required this.morningCount,
    required this.afternoonCount,
    required this.eveningCount,
    required this.captionedCount,
    required this.photographedCount,
    required this.uniqueFlavorsCount,
  });
}

class FlavorCount {
  final String name;
  final int count;
  const FlavorCount(this.name, this.count);
}

/// Rating-per-peso, flavor frequency, roast drift — all with "not enough data" fallbacks
/// handled at the UI layer via the nullable/empty fields here.
class CoffeeInsights {
  final List<FlavorCount> flavors;
  final BestValueCup? bestValue;
  final String? recentRoast;
  final String? olderRoast;
  final int roastedCount;

  const CoffeeInsights({
    required this.flavors,
    required this.bestValue,
    required this.recentRoast,
    required this.olderRoast,
    required this.roastedCount,
  });
}

class BestValueCup {
  final String label;
  final int rating;
  final double price;
  final DateTime date;
  const BestValueCup({
    required this.label,
    required this.rating,
    required this.price,
    required this.date,
  });
}
