import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/badges.dart';
import '../logic/date_utils.dart';
import '../logic/streak.dart';
import '../providers/cupboard_controller.dart';
import '../providers/derived_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/streak_icon.dart';

Future<void> showStreakSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const StreakSheet(),
  );
}

class StreakSheet extends ConsumerWidget {
  const StreakSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(cupboardControllerProvider).valueOrNull;
    final stats = ref.watch(statsProvider);
    if (state == null || stats == null) return const SizedBox.shrink();

    final today = todayDate();
    final weekDays = List.generate(7, (i) => offsetDate(today, i - 6));

    final streakBadges = kBadges.where((b) => b.group == 'Streaks').toList();
    BadgeDef? next;
    for (final b in streakBadges) {
      if (stats.bestStreak < b.need) {
        next = b;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your streak', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            Center(
              child: Column(
                children: [
                  StreakIcon(size: 46, color: c.amber),
                  const SizedBox(height: 6),
                  Text('${stats.streak}',
                      style: TextStyle(
                          fontFamily: 'monospace', fontSize: 34, fontWeight: FontWeight.w700, color: c.ink)),
                  Text('day streak', style: TextStyle(fontSize: 13, color: c.inkSoft)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((d) {
                final status =
                    dayStatusFor(d, entries: state.entries, freezeDates: state.freezeDates);
                final isToday = isSameDate(d, today);
                Color bg;
                switch (status) {
                  case DayStatus.real:
                    bg = c.amber;
                  case DayStatus.skip:
                    bg = c.sage;
                  default:
                    bg = c.surface2;
                }
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: status == DayStatus.freeze
                              ? c.amber
                              : (isToday ? c.ink : c.line),
                          width: isToday || status == DayStatus.freeze ? 2 : 1,
                          style: status == DayStatus.freeze ? BorderStyle.solid : BorderStyle.solid,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(weekdayInitial(d), style: TextStyle(fontSize: 10.5, color: c.inkFaint)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('dashed ring = covered by a rain check',
                  style: TextStyle(fontSize: 12, color: c.inkFaint)),
            ),
            const SizedBox(height: 10),
            _row(c, 'Longest streak', '${stats.bestStreak} days'),
            _row(c, 'Rain checks saved', '${state.settings.freezeBank}'),
            const SizedBox(height: 6),
            Text(
              "Earn one every 7-day streak — it quietly covers a day you miss so your streak doesn't reset.",
              style: TextStyle(fontSize: 12, color: c.inkFaint),
            ),
            const SizedBox(height: 14),
            if (next != null) ...[
              Text(
                '${(next.need - stats.streak).clamp(0, next.need)} more day(s) to ${next.name}',
                style: TextStyle(fontSize: 12, color: c.inkFaint),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (stats.streak / next.need).clamp(0, 1),
                  minHeight: 5,
                  backgroundColor: c.surface2,
                  valueColor: AlwaysStoppedAnimation(c.amber),
                ),
              ),
            ] else
              Text("You've earned every streak title. Impressive.",
                  style: TextStyle(fontSize: 12, color: c.inkFaint)),
          ],
        ),
      ),
    );
  }

  Widget _row(AppColors c, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: c.inkSoft, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: c.ink, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
