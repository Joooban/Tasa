import '../models/stats.dart';
import 'constants.dart';

class BadgeDef {
  final String id;
  final String name;
  final String desc;
  final String group;
  final int need;
  final int Function(CoffeeStats s) calc;

  const BadgeDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.group,
    required this.need,
    required this.calc,
  });

  bool isUnlocked(CoffeeStats s) => calc(s) >= need;

  /// 0-100, clamped — for progress bars on locked badges.
  int progressPercent(CoffeeStats s) {
    final pct = (100 * calc(s) / need).round();
    return pct.clamp(0, 100);
  }
}

int _homeRatioAllTimePercent(CoffeeStats s) {
  if (s.totalCups < 10) return 0;
  return (100 * s.homeCount / s.totalCups).round();
}

/// Every earnable title, across all axes. Badges compute live from entry history —
/// nothing here is frozen or recalculated on a schedule. Multi-tier badges (I/II/III)
/// share one underlying count, so unlocking a higher tier never un-earns a lower one.
final List<BadgeDef> kBadges = [
  // ---------------- Milestones ----------------
  BadgeDef(
    id: 'first_cup',
    name: 'First Cup',
    desc: 'Logged your first cup',
    group: 'Milestones',
    need: 1,
    calc: (s) => s.totalCups,
  ),
  BadgeDef(
    id: 'cups_50',
    name: '50 Cups Club',
    desc: '50 cups logged',
    group: 'Milestones',
    need: 50,
    calc: (s) => s.totalCups,
  ),
  BadgeDef(
    id: 'cups_100',
    name: '100 Cups Club',
    desc: '100 cups logged',
    group: 'Milestones',
    need: 100,
    calc: (s) => s.totalCups,
  ),
  BadgeDef(
    id: 'cups_500',
    name: '500 Cups Club',
    desc: '500 cups logged',
    group: 'Milestones',
    need: 500,
    calc: (s) => s.totalCups,
  ),
  BadgeDef(
    id: 'cups_1000',
    name: '1000 Cups Club',
    desc: '1,000 cups logged',
    group: 'Milestones',
    need: 1000,
    calc: (s) => s.totalCups,
  ),

  // ---------------- Home dedication ----------------
  BadgeDef(
    id: 'home_10',
    name: 'Home Brewer',
    desc: '10 cups brewed at home',
    group: 'Home dedication',
    need: 10,
    calc: (s) => s.homeCount,
  ),
  BadgeDef(
    id: 'home_50',
    name: 'Dedicated Home Brewer',
    desc: '50 cups brewed at home',
    group: 'Home dedication',
    need: 50,
    calc: (s) => s.homeCount,
  ),
  BadgeDef(
    id: 'home_200',
    name: 'Home Brewing Master',
    desc: '200 cups brewed at home',
    group: 'Home dedication',
    need: 200,
    calc: (s) => s.homeCount,
  ),
  BadgeDef(
    id: 'home_500',
    name: 'Home Brewing Legend',
    desc: '500 cups brewed at home',
    group: 'Home dedication',
    need: 500,
    calc: (s) => s.homeCount,
  ),

  // ---------------- Exploration ----------------
  BadgeDef(
    id: 'cafe_5',
    name: 'Café Explorer',
    desc: '5 different cafés visited',
    group: 'Exploration',
    need: 5,
    calc: (s) => s.uniqueCafes,
  ),
  BadgeDef(
    id: 'cafe_15',
    name: 'Café Connoisseur',
    desc: '15 different cafés visited',
    group: 'Exploration',
    need: 15,
    calc: (s) => s.uniqueCafes,
  ),
  BadgeDef(
    id: 'cafe_30',
    name: 'City Roaster Hunter',
    desc: '30 different cafés visited',
    group: 'Exploration',
    need: 30,
    calc: (s) => s.uniqueCafes,
  ),
  BadgeDef(
    id: 'cafe_50',
    name: 'Local Legend',
    desc: '50 different cafés visited',
    group: 'Exploration',
    need: 50,
    calc: (s) => s.uniqueCafes,
  ),
  BadgeDef(
    id: 'method_5',
    name: 'Method Explorer',
    desc: 'Tried 5 different methods',
    group: 'Exploration',
    need: 5,
    calc: (s) => s.uniqueMethods,
  ),
  BadgeDef(
    id: 'method_all',
    name: 'Jack of All Brews',
    desc: 'Tried every listed method',
    group: 'Exploration',
    need: kBrewMethods.length,
    calc: (s) => s.uniqueListedMethods,
  ),
  BadgeDef(
    id: 'flavor_5',
    name: 'Flavor Adventurer I',
    desc: '5 different flavor notes used',
    group: 'Exploration',
    need: 5,
    calc: (s) => s.uniqueFlavorsCount,
  ),
  BadgeDef(
    id: 'flavor_10',
    name: 'Flavor Adventurer II',
    desc: '10 different flavor notes used',
    group: 'Exploration',
    need: 10,
    calc: (s) => s.uniqueFlavorsCount,
  ),
  BadgeDef(
    id: 'flavor_18',
    name: 'Flavor Adventurer III',
    desc: '18 different flavor notes used — you\'re naming your own by now',
    group: 'Exploration',
    need: 18,
    calc: (s) => s.uniqueFlavorsCount,
  ),

  // ---------------- Loyalty ----------------
  BadgeDef(
    id: 'loyal_5',
    name: 'Regular',
    desc: 'Visited one café 5 times',
    group: 'Loyalty',
    need: 5,
    calc: (s) => s.maxSameCafe,
  ),
  BadgeDef(
    id: 'loyal_15',
    name: 'The Usual',
    desc: 'Visited one café 15 times',
    group: 'Loyalty',
    need: 15,
    calc: (s) => s.maxSameCafe,
  ),
  BadgeDef(
    id: 'loyal_30',
    name: 'Café Loyalist',
    desc: 'Visited one café 30 times',
    group: 'Loyalty',
    need: 30,
    calc: (s) => s.maxSameCafe,
  ),
  BadgeDef(
    id: 'loyal_50',
    name: 'Café Family',
    desc: 'Visited one café 50 times',
    group: 'Loyalty',
    need: 50,
    calc: (s) => s.maxSameCafe,
  ),

  // ---------------- Streaks ----------------
  BadgeDef(
    id: 'streak_7',
    name: 'Consistent Sipper',
    desc: '7-day logging streak',
    group: 'Streaks',
    need: 7,
    calc: (s) => s.bestStreak,
  ),
  BadgeDef(
    id: 'streak_30',
    name: 'Ritualist',
    desc: '30-day logging streak',
    group: 'Streaks',
    need: 30,
    calc: (s) => s.bestStreak,
  ),
  BadgeDef(
    id: 'streak_100',
    name: 'Unbreakable',
    desc: '100-day logging streak',
    group: 'Streaks',
    need: 100,
    calc: (s) => s.bestStreak,
  ),
  BadgeDef(
    id: 'streak_365',
    name: 'Year-Round Ritual',
    desc: '365-day logging streak',
    group: 'Streaks',
    need: 365,
    calc: (s) => s.bestStreak,
  ),

  // ---------------- Habits (leveled) ----------------
  BadgeDef(
    id: 'early_bird_1',
    name: 'Early Bird I',
    desc: '15 morning cups logged',
    group: 'Habits',
    need: 15,
    calc: (s) => s.morningCount,
  ),
  BadgeDef(
    id: 'early_bird_2',
    name: 'Early Bird II',
    desc: '50 morning cups logged',
    group: 'Habits',
    need: 50,
    calc: (s) => s.morningCount,
  ),
  BadgeDef(
    id: 'early_bird_3',
    name: 'Early Bird III',
    desc: '150 morning cups logged',
    group: 'Habits',
    need: 150,
    calc: (s) => s.morningCount,
  ),
  BadgeDef(
    id: 'night_owl_1',
    name: 'Night Owl I',
    desc: '15 evening cups logged',
    group: 'Habits',
    need: 15,
    calc: (s) => s.eveningCount,
  ),
  BadgeDef(
    id: 'night_owl_2',
    name: 'Night Owl II',
    desc: '50 evening cups logged',
    group: 'Habits',
    need: 50,
    calc: (s) => s.eveningCount,
  ),
  BadgeDef(
    id: 'night_owl_3',
    name: 'Night Owl III',
    desc: '150 evening cups logged',
    group: 'Habits',
    need: 150,
    calc: (s) => s.eveningCount,
  ),
  const BadgeDef(
    id: 'frugal_1',
    name: 'Frugal Brewer I',
    desc: '60%+ home-brewed overall (10+ cups logged)',
    group: 'Habits',
    need: 60,
    calc: _homeRatioAllTimePercent,
  ),
  const BadgeDef(
    id: 'frugal_2',
    name: 'Frugal Brewer II',
    desc: '80%+ home-brewed overall (10+ cups logged)',
    group: 'Habits',
    need: 80,
    calc: _homeRatioAllTimePercent,
  ),
  const BadgeDef(
    id: 'frugal_3',
    name: 'Frugal Brewer III',
    desc: '95%+ home-brewed overall (10+ cups logged)',
    group: 'Habits',
    need: 95,
    calc: _homeRatioAllTimePercent,
  ),

  // ---------------- Documentation ----------------
  BadgeDef(
    id: 'storyteller_1',
    name: 'Storyteller I',
    desc: '10 cups logged with a caption',
    group: 'Documentation',
    need: 10,
    calc: (s) => s.captionedCount,
  ),
  BadgeDef(
    id: 'storyteller_2',
    name: 'Storyteller II',
    desc: '50 cups logged with a caption',
    group: 'Documentation',
    need: 50,
    calc: (s) => s.captionedCount,
  ),
  BadgeDef(
    id: 'storyteller_3',
    name: 'Storyteller III',
    desc: '150 cups logged with a caption',
    group: 'Documentation',
    need: 150,
    calc: (s) => s.captionedCount,
  ),
  BadgeDef(
    id: 'photographer_1',
    name: 'Photographer I',
    desc: '10 cups logged with a photo',
    group: 'Documentation',
    need: 10,
    calc: (s) => s.photographedCount,
  ),
  BadgeDef(
    id: 'photographer_2',
    name: 'Photographer II',
    desc: '50 cups logged with a photo',
    group: 'Documentation',
    need: 50,
    calc: (s) => s.photographedCount,
  ),
  BadgeDef(
    id: 'photographer_3',
    name: 'Photographer III',
    desc: '150 cups logged with a photo',
    group: 'Documentation',
    need: 150,
    calc: (s) => s.photographedCount,
  ),

  // ---------------- Method mastery ----------------
  BadgeDef(
    id: 'm_pourover',
    name: 'Pour-Over Enthusiast',
    desc: '20 pour-over cups',
    group: 'Method mastery',
    need: 20,
    calc: (s) => s.methodCounts['Pour-over (V60)'] ?? 0,
  ),
  BadgeDef(
    id: 'm_espresso',
    name: 'Espresso Devotee',
    desc: '20 espresso cups',
    group: 'Method mastery',
    need: 20,
    calc: (s) => s.methodCounts['Espresso'] ?? 0,
  ),
  BadgeDef(
    id: 'm_aeropress',
    name: 'AeroPress Adept',
    desc: '20 AeroPress cups',
    group: 'Method mastery',
    need: 20,
    calc: (s) => s.methodCounts['AeroPress'] ?? 0,
  ),
  BadgeDef(
    id: 'm_frenchpress',
    name: 'French Press Fan',
    desc: '20 French press cups',
    group: 'Method mastery',
    need: 20,
    calc: (s) => s.methodCounts['French press'] ?? 0,
  ),
  BadgeDef(
    id: 'm_coldbrew',
    name: 'Cold Brew Aficionado',
    desc: '20 cold brew cups',
    group: 'Method mastery',
    need: 20,
    calc: (s) => s.methodCounts['Cold brew'] ?? 0,
  ),
  BadgeDef(
    id: 'm_caramelmacchiato',
    name: 'Caramel Macchiato Regular',
    desc: '20 caramel macchiatos',
    group: 'Method mastery',
    need: 20,
    calc: (s) => s.methodCounts['Caramel Macchiato'] ?? 0,
  ),
  BadgeDef(
    id: 'm_spanishlatte',
    name: 'Spanish Latte Loyalist',
    desc: '20 Spanish lattes',
    group: 'Method mastery',
    need: 20,
    calc: (s) => s.methodCounts['Spanish Latte'] ?? 0,
  ),
];

List<BadgeDef> unlockedBadges(CoffeeStats s) =>
    kBadges.where((b) => b.isUnlocked(s)).toList();

/// Badges grouped in registration order, for the shelf view.
Map<String, List<BadgeDef>> badgesByGroup() {
  final groups = <String, List<BadgeDef>>{};
  for (final b in kBadges) {
    groups.putIfAbsent(b.group, () => []).add(b);
  }
  return groups;
}
