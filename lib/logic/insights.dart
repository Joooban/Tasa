import '../models/entry.dart';
import '../models/stats.dart';
import 'stats.dart';

/// Pure port of the prototype's `computeInsights()`.
CoffeeInsights computeInsights(List<Entry> entries) {
  final real = realEntries(entries);

  final flavorCounts = <String, int>{};
  for (final e in real) {
    for (final f in e.flavors) {
      flavorCounts[f] = (flavorCounts[f] ?? 0) + 1;
    }
  }
  final flavorList = flavorCounts.entries.map((e) => FlavorCount(e.key, e.value)).toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  final priced =
      real.where((e) => !e.free && (e.price ?? 0) > 0 && e.rating > 0).toList();
  BestValueCup? bestValue;
  var bestRatio = -1.0;
  for (final e in priced) {
    final ratio = e.rating / e.price!;
    if (ratio > bestRatio) {
      bestRatio = ratio;
      bestValue = BestValueCup(
        label: e.kind == EntryKind.home ? (e.method ?? 'Home brew') : (e.venueName ?? 'Away'),
        rating: e.rating,
        price: e.price!,
        date: e.date,
      );
    }
  }

  final roasted = real.where((e) => e.roast != null).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  final recent = roasted.take(10).toList();
  final older = roasted.skip(10).toList();

  String? roastMode(List<Entry> list) {
    final c = {'light': 0, 'medium': 0, 'dark': 0};
    for (final e in list) {
      c[e.roast!.id] = (c[e.roast!.id] ?? 0) + 1;
    }
    String? top;
    var max = 0;
    c.forEach((k, v) {
      if (v > max) {
        max = v;
        top = k;
      }
    });
    return max > 0 ? top : null;
  }

  return CoffeeInsights(
    flavors: flavorList,
    bestValue: bestValue,
    recentRoast: roastMode(recent),
    olderRoast: roastMode(older),
    roastedCount: roasted.length,
  );
}
