import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/badges.dart';
import '../logic/format.dart';
import '../models/stats.dart';
import '../providers/cupboard_controller.dart';
import '../providers/derived_providers.dart';
import '../providers/services_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/wrapped_card.dart';

class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});

  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cupboard = ref.watch(cupboardControllerProvider).valueOrNull;
    final stats = ref.watch(statsProvider);
    final insights = ref.watch(insightsProvider);
    if (cupboard == null || stats == null || insights == null) {
      return const SizedBox.shrink();
    }

    final recentBadges = unlockedBadges(stats).reversed.take(3).toList().reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(fmtMonthYear(DateTime.now()),
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c.inkSoft)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: cupboard.settings.hideAmount,
              onChanged: (v) =>
                  ref.read(cupboardControllerProvider.notifier).setHideAmount(v ?? false),
            ),
            Text('hide amount when sharing', style: TextStyle(fontSize: 13, color: c.inkSoft)),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: RepaintBoundary(
            key: _boundaryKey,
            child: WrappedCard(
              stats: stats,
              profileName: cupboard.profile.name,
              hideAmount: cupboard.settings.hideAmount,
              recentBadges: recentBadges,
              jokeSeed: cupboard.entries.length,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: ElevatedButton.icon(
            onPressed: _sharing ? null : _share,
            icon: const Icon(Icons.share_outlined, size: 16),
            label: Text(_sharing ? 'Preparing…' : 'Share'),
          ),
        ),
        const SizedBox(height: 24),
        Text('YOUR COFFEE PROFILE',
            style: TextStyle(
                fontSize: 13, letterSpacing: 1, color: c.inkSoft, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flavor profile', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (insights.flavors.isEmpty)
                Text(
                  'Tag a flavor note or two next time you log a cup, and your profile will take shape here.',
                  style: TextStyle(fontSize: 13, color: c.inkSoft),
                )
              else
                ...insights.flavors.take(6).map((f) {
                  final max = insights.flavors.first.count;
                  final pct = f.count / max;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(f.name, style: const TextStyle(fontSize: 13)),
                            Text('${f.count}',
                                style: TextStyle(
                                    fontSize: 13, fontFamily: 'monospace', color: c.inkSoft)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: c.surface2,
                            valueColor: AlwaysStoppedAnimation(c.amber),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
              Text('Best value cup', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                insights.bestValue == null
                    ? 'Rate a few priced cups and your best-value pick will show up here.'
                    : '${insights.bestValue!.label} — ${insights.bestValue!.rating} beans for ${peso(insights.bestValue!.price)}, on ${fmtShortDate(insights.bestValue!.date)}.',
                style: TextStyle(fontSize: 13, color: c.inkSoft),
              ),
              const SizedBox(height: 12),
              Text('Roast trend', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(_roastTrendText(insights), style: TextStyle(fontSize: 13, color: c.inkSoft)),
            ],
          ),
        ),
      ],
    );
  }

  String _roastTrendText(CoffeeInsights insights) {
    if (insights.roastedCount < 3) {
      return 'Log a few more roast levels to see whether your taste is drifting lighter or darker.';
    }
    const label = {'light': 'light roast', 'medium': 'medium roast', 'dark': 'dark roast'};
    if (insights.recentRoast != null &&
        insights.olderRoast != null &&
        insights.recentRoast != insights.olderRoast) {
      return "Lately you've been leaning ${label[insights.recentRoast]}, a shift from ${label[insights.olderRoast]} before.";
    }
    if (insights.recentRoast != null) {
      return 'Steady preference for ${label[insights.recentRoast]} — no drift yet.';
    }
    return 'Not enough roast data yet.';
  }

  Future<void> _share() async {
    final cupboard = ref.read(cupboardControllerProvider).valueOrNull;
    final stats = ref.read(statsProvider);
    if (cupboard == null || stats == null) return;
    setState(() => _sharing = true);
    final name = cupboard.profile.name.trim();
    final hide = cupboard.settings.hideAmount;
    final lines = [
      name.isNotEmpty ? "$name's coffee month on Tasa ☕" : 'My coffee month on Tasa ☕',
      hide ? 'Spend: kept private' : 'Spend: ${peso(stats.monthSpend)}',
      'Cups: ${stats.monthEntryCount} (${stats.monthHomeCount} home, ${stats.monthAwayCount} away)',
      if (stats.topCafe != null) 'Top café: ${stats.topCafe}',
      if (stats.topMethod != null) 'Go-to method: ${stats.topMethod}',
      'Longest streak: ${stats.bestStreak} days',
    ];
    try {
      await ref.read(shareServiceProvider).shareWrappedCard(
            boundaryKey: _boundaryKey,
            fallbackText: lines.join('\n'),
          );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}
