import 'package:flutter/material.dart';

import '../logic/badges.dart';
import '../models/stats.dart';
import '../theme/app_colors.dart';
import 'bean_icon.dart';

class BadgeCell extends StatelessWidget {
  final BadgeDef badge;
  final CoffeeStats stats;

  const BadgeCell({super.key, required this.badge, required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unlocked = badge.isUnlocked(stats);
    final value = badge.calc(stats);

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            BeanIcon(size: 30, color: unlocked ? c.amber : c.inkFaint),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 3),
            Text(
              badge.desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: c.inkSoft),
            ),
            if (!unlocked) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: badge.progressPercent(stats) / 100,
                  minHeight: 5,
                  backgroundColor: c.surface2,
                  valueColor: AlwaysStoppedAnimation(c.amber),
                ),
              ),
              const SizedBox(height: 4),
              Text('$value / ${badge.need}', style: TextStyle(fontSize: 12, color: c.inkFaint)),
            ],
          ],
        ),
      ),
    );
  }
}
