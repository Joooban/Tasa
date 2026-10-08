import '../models/entry.dart';

/// Real (non-sample, non-skip) entries logged on this exact calendar date in
/// a previous year — "On this day" memories, most-recent-year first.
List<Entry> onThisDay(List<Entry> entries, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final matches = entries
      .where((e) =>
          e.kind != EntryKind.skip &&
          !e.isSample &&
          e.date.year < today.year &&
          e.date.month == today.month &&
          e.date.day == today.day)
      .toList();
  matches.sort((a, b) => b.date.compareTo(a.date));
  return matches;
}
