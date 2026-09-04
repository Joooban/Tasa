import 'package:flutter_test/flutter_test.dart';
import 'package:tasa/logic/badges.dart';
import 'package:tasa/models/stats.dart';

CoffeeStats _statsWith({
  int totalCups = 0,
  int homeCount = 0,
  int uniqueCafes = 0,
  int maxSameCafe = 0,
  int bestStreak = 0,
  double homeRatioThisMonth = 0,
  bool mostlyMorning = false,
  bool mostlyEvening = false,
  int uniqueMethods = 0,
  int uniqueListedMethods = 0,
  Map<String, int> methodCounts = const {},
  int morningCount = 0,
  int afternoonCount = 0,
  int eveningCount = 0,
  int captionedCount = 0,
  int photographedCount = 0,
  int uniqueFlavorsCount = 0,
}) {
  return CoffeeStats(
    totalCups: totalCups,
    homeCount: homeCount,
    awayCount: 0,
    monthSpend: 0,
    monthHomeSpend: 0,
    monthAwaySpend: 0,
    monthSavings: 0,
    topCafe: null,
    maxSameCafe: maxSameCafe,
    uniqueCafes: uniqueCafes,
    topMethod: null,
    uniqueMethods: uniqueMethods,
    uniqueListedMethods: uniqueListedMethods,
    methodCounts: methodCounts,
    streak: 0,
    bestStreak: bestStreak,
    homeRatioThisMonth: homeRatioThisMonth,
    mostlyMorning: mostlyMorning,
    mostlyEvening: mostlyEvening,
    monthEntryCount: 0,
    monthHomeCount: 0,
    monthAwayCount: 0,
    morningCount: morningCount,
    afternoonCount: afternoonCount,
    eveningCount: eveningCount,
    captionedCount: captionedCount,
    photographedCount: photographedCount,
    uniqueFlavorsCount: uniqueFlavorsCount,
  );
}

void main() {
  test('first_cup unlocks at exactly one logged cup, not zero', () {
    final def = kBadges.firstWhere((b) => b.id == 'first_cup');
    expect(def.isUnlocked(_statsWith(totalCups: 0)), isFalse);
    expect(def.isUnlocked(_statsWith(totalCups: 1)), isTrue);
  });

  test('loyalty badges key off the single most-visited café, not total cafés', () {
    final def = kBadges.firstWhere((b) => b.id == 'loyal_5');
    // Five cafés visited once each should NOT unlock "Regular" (needs 5 visits to ONE café).
    expect(def.isUnlocked(_statsWith(uniqueCafes: 5, maxSameCafe: 1)), isFalse);
    expect(def.isUnlocked(_statsWith(uniqueCafes: 1, maxSameCafe: 5)), isTrue);
  });

  test('frugal brewer tiers key off all-time home ratio, gated by a minimum sample size', () {
    final tier1 = kBadges.firstWhere((b) => b.id == 'frugal_1');
    final tier2 = kBadges.firstWhere((b) => b.id == 'frugal_2');
    // 9/10 cups at home is a 90% ratio, but under the 10-cup minimum it doesn't count yet.
    expect(tier1.isUnlocked(_statsWith(totalCups: 9, homeCount: 9)), isFalse);
    expect(tier1.isUnlocked(_statsWith(totalCups: 10, homeCount: 6)), isTrue); // 60%
    expect(tier2.isUnlocked(_statsWith(totalCups: 10, homeCount: 6)), isFalse); // needs 80%
    expect(tier2.isUnlocked(_statsWith(totalCups: 10, homeCount: 8)), isTrue);
  });

  test('early bird tiers unlock independently as morning count climbs', () {
    final tier1 = kBadges.firstWhere((b) => b.id == 'early_bird_1');
    final tier2 = kBadges.firstWhere((b) => b.id == 'early_bird_2');
    final tier3 = kBadges.firstWhere((b) => b.id == 'early_bird_3');
    final stats = _statsWith(morningCount: 60);
    expect(tier1.isUnlocked(stats), isTrue);
    expect(tier2.isUnlocked(stats), isTrue);
    expect(tier3.isUnlocked(stats), isFalse);
  });

  test('documentation badges track captions and photos independently', () {
    final storyteller = kBadges.firstWhere((b) => b.id == 'storyteller_1');
    final photographer = kBadges.firstWhere((b) => b.id == 'photographer_1');
    final stats = _statsWith(captionedCount: 10, photographedCount: 3);
    expect(storyteller.isUnlocked(stats), isTrue);
    expect(photographer.isUnlocked(stats), isFalse);
  });

  test('method_all requires every listed method, not just many distinct ones', () {
    final def = kBadges.firstWhere((b) => b.id == 'method_all');
    // Lots of unique methods overall, but none from the canonical list.
    expect(def.isUnlocked(_statsWith(uniqueMethods: 20, uniqueListedMethods: 0)), isFalse);
  });

  test('progressPercent clamps at 100 and never exceeds it past the goal', () {
    final def = kBadges.firstWhere((b) => b.id == 'home_10');
    expect(def.progressPercent(_statsWith(homeCount: 20)), 100);
    expect(def.progressPercent(_statsWith(homeCount: 5)), 50);
  });

  test('unlockedBadges only returns badges whose condition is met', () {
    final stats = _statsWith(totalCups: 1, homeCount: 0);
    final unlocked = unlockedBadges(stats);
    expect(unlocked.map((b) => b.id), contains('first_cup'));
    expect(unlocked.map((b) => b.id), isNot(contains('cups_50')));
  });

  test('badgesByGroup partitions every badge into exactly one group', () {
    final groups = badgesByGroup();
    final totalGrouped = groups.values.fold<int>(0, (a, l) => a + l.length);
    expect(totalGrouped, kBadges.length);
  });

  test('every badge id is unique', () {
    final ids = kBadges.map((b) => b.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
