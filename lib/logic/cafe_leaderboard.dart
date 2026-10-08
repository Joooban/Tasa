import '../models/entry.dart';
import 'stats.dart';

class CafeRanking {
  final String name;
  final int visitCount;
  final double totalSpend;
  final double avgRating;
  const CafeRanking({
    required this.name,
    required this.visitCount,
    required this.totalSpend,
    required this.avgRating,
  });
}

/// Every café visited, ranked by visit count (most-visited first) — the
/// full picture behind the single "top café" stat shown elsewhere.
List<CafeRanking> cafeLeaderboard(List<Entry> entries) {
  final real = realEntries(entries).where((e) =>
      e.kind == EntryKind.away &&
      e.venueTag == VenueTag.cafe &&
      (e.venueName ?? '').isNotEmpty);

  final byName = <String, List<Entry>>{};
  for (final e in real) {
    byName.putIfAbsent(e.venueName!, () => []).add(e);
  }

  final rankings = byName.entries.map((entry) {
    final visits = entry.value;
    final spend = visits.fold(0.0, (a, e) => a + (e.free ? 0 : (e.price ?? 0)));
    final ratedVisits = visits.where((e) => e.rating > 0).toList();
    final avgRating = ratedVisits.isNotEmpty
        ? ratedVisits.fold(0, (a, e) => a + e.rating) / ratedVisits.length
        : 0.0;
    return CafeRanking(
      name: entry.key,
      visitCount: visits.length,
      totalSpend: spend,
      avgRating: avgRating.toDouble(),
    );
  }).toList();

  rankings.sort((a, b) {
    final byVisits = b.visitCount.compareTo(a.visitCount);
    if (byVisits != 0) return byVisits;
    final bySpend = b.totalSpend.compareTo(a.totalSpend);
    if (bySpend != 0) return bySpend;
    return a.name.compareTo(b.name);
  });
  return rankings;
}
