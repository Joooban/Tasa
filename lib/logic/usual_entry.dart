import '../models/entry.dart';

/// The entry whose (kind, method, venueName) combination appears most often
/// among real entries — used as a one-tap "log my usual" template. Returns
/// null with fewer than 3 real entries, so a brand-new cupboard doesn't
/// suggest a "usual" built from a single coincidental cup.
Entry? usualEntry(List<Entry> entries) {
  final real = entries.where((e) => e.kind != EntryKind.skip && !e.isSample).toList();
  if (real.length < 3) return null;

  String keyOf(Entry e) => '${e.kind.name}|${e.method ?? ''}|${e.venueName ?? ''}';
  final counts = <String, int>{};
  final mostRecentByKey = <String, Entry>{};
  for (final e in real) {
    final k = keyOf(e);
    counts[k] = (counts[k] ?? 0) + 1;
    final current = mostRecentByKey[k];
    if (current == null || e.date.isAfter(current.date)) {
      mostRecentByKey[k] = e;
    }
  }
  final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
  final tiedKeys = counts.entries.where((e) => e.value == maxCount).map((e) => e.key);

  Entry? best;
  for (final k in tiedKeys) {
    final candidate = mostRecentByKey[k]!;
    if (best == null || candidate.date.isAfter(best.date)) best = candidate;
  }
  return best;
}
