import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/badges.dart';
import '../providers/derived_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/badge_cell.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final stats = ref.watch(statsProvider);
    if (stats == null) return const SizedBox.shrink();
    final groups = badgesByGroup();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text(
          "Titles unlock as you log — no monthly reset, just what you've actually earned.",
          style: TextStyle(fontSize: 13.5, color: c.inkSoft),
        ),
        const SizedBox(height: 4),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 10),
            child: Text(
              entry.key.toUpperCase(),
              style: TextStyle(
                  fontSize: 13, letterSpacing: 1, color: c.inkSoft, fontWeight: FontWeight.w600),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entry.value.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisExtent: 190,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, i) => BadgeCell(badge: entry.value[i], stats: stats),
          ),
        ],
      ],
    );
  }
}
