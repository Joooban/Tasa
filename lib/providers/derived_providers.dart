import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/badges.dart';
import '../logic/constants.dart';
import '../logic/insights.dart';
import '../logic/stats.dart';
import '../models/entry.dart';
import '../models/stats.dart';
import 'cupboard_controller.dart';

CoffeeStats? statsOf(CupboardState? s) {
  if (s == null) return null;
  return computeStats(entries: s.entries, beanProfile: s.beanProfile, freezeDates: s.freezeDates);
}

final statsProvider = Provider<CoffeeStats?>((ref) {
  final s = ref.watch(cupboardControllerProvider).valueOrNull;
  return statsOf(s);
});

final insightsProvider = Provider<CoffeeInsights?>((ref) {
  final s = ref.watch(cupboardControllerProvider).valueOrNull;
  if (s == null) return null;
  return computeInsights(s.entries);
});

final unlockedBadgesProvider = Provider<List<BadgeDef>>((ref) {
  final stats = ref.watch(statsProvider);
  if (stats == null) return const [];
  return unlockedBadges(stats);
});

enum CupboardFilter { all, home, away }

final cupboardFilterProvider = StateProvider<CupboardFilter>((ref) => CupboardFilter.all);

/// Distinct café/venue names seen so far, for the "Where" autocomplete.
final venueNamesProvider = Provider<List<String>>((ref) {
  final s = ref.watch(cupboardControllerProvider).valueOrNull;
  if (s == null) return const [];
  final names = <String>{};
  for (final e in s.entries) {
    if (e.kind == EntryKind.away && (e.venueName ?? '').isNotEmpty) {
      names.add(e.venueName!);
    }
  }
  return names.toList()..sort();
});

/// The built-in flavor tags plus any custom ones the user has typed before —
/// so a custom flavor becomes a reusable suggestion, not a one-off.
final flavorSuggestionsProvider = Provider<List<String>>((ref) {
  final s = ref.watch(cupboardControllerProvider).valueOrNull;
  final custom = <String>{};
  if (s != null) {
    for (final e in s.entries) {
      for (final f in e.flavors) {
        if (!kFlavorTags.contains(f)) custom.add(f);
      }
    }
  }
  final sortedCustom = custom.toList()..sort();
  return [...kFlavorTags, ...sortedCustom];
});
