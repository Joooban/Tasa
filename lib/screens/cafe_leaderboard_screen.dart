import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/cafe_leaderboard.dart';
import '../logic/format.dart';
import '../providers/cupboard_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/bean_icon.dart';

/// The full café ranking behind the single "Top café" line shown in
/// Wrapped — every place visited, most-visited first.
class CafeLeaderboardScreen extends ConsumerWidget {
  const CafeLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final entries = ref.watch(cupboardControllerProvider).valueOrNull?.entries ?? const [];
    final ranking = cafeLeaderboard(entries);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(backgroundColor: c.bg, elevation: 0, title: const Text('Café leaderboard')),
      body: ranking.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Log a few café visits and your leaderboard will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.inkSoft),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ranking.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = ranking[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: c.clay.withValues(alpha: 0.18), shape: BoxShape.circle),
                        child: Text('${i + 1}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: c.clayInk)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(
                              '${r.visitCount} visit${r.visitCount == 1 ? '' : 's'} · ${peso(r.totalSpend)} total',
                              style: TextStyle(fontSize: 12, color: c.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      if (r.avgRating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BeanIcon(size: 14, color: c.amber),
                            const SizedBox(width: 3),
                            Text(r.avgRating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink)),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
