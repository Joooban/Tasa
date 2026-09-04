import 'package:flutter/material.dart';

import '../logic/badges.dart';
import '../logic/format.dart';
import '../logic/wrapped_joke.dart';
import '../models/stats.dart';
import '../theme/app_colors.dart';
import 'bean_icon.dart';

/// The monthly summary card — the app's retention hook and organic distribution
/// mechanism. Designed to be screenshotted or shared as a real image.
class WrappedCard extends StatelessWidget {
  final CoffeeStats stats;
  final String? profileName;
  final bool hideAmount;
  final List<BadgeDef> recentBadges;
  final int jokeSeed;

  const WrappedCard({
    super.key,
    required this.stats,
    required this.profileName,
    required this.hideAmount,
    required this.recentBadges,
    required this.jokeSeed,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = (profileName ?? '').trim();
    final amountText = hideAmount ? '₱•••' : peso(stats.monthSpend);
    final joke = hideAmount ? null : jokeFor(stats.monthSpend, jokeSeed);
    final onEspresso = c.onEspresso;
    final cardRadius = BorderRadius.circular(22);

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
      // A single decorated Container (fill + shadow + a foreground glow) —
      // deliberately not a Stack/ClipRRect: inside a scrolling ListView the
      // height constraint is unbounded, and a Stack's non-positioned
      // background child collapses to zero size in that case, leaving the
      // card looking like a hazy, empty shadow instead of a filled card.
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.espressoGradientStart, c.espressoGradientMid, c.espressoGradientEnd],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [BoxShadow(color: c.espressoShadow, blurRadius: 28, offset: const Offset(0, 10))],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: cardRadius,
        gradient: RadialGradient(
          center: const Alignment(0.9, -0.9),
          radius: 0.75,
          colors: [c.amber.withValues(alpha: 0.28), c.amber.withValues(alpha: 0.0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isNotEmpty ? "$name’s month in coffee" : 'Your month in coffee',
            style: TextStyle(
              color: onEspresso.withValues(alpha: 0.75),
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amountText,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: onEspresso,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                ),
          ),
          if (joke != null) ...[
            const SizedBox(height: 2),
            Text(joke, style: TextStyle(color: onEspresso.withValues(alpha: 0.8), fontSize: 13.5)),
          ],
          const SizedBox(height: 18),
          _row('Cups this month', '${stats.monthEntryCount}', onEspresso),
          _row('Home-brewed', '${stats.monthHomeCount}', onEspresso),
          _row('Away', '${stats.monthAwayCount}', onEspresso),
          _row('Est. saved brewing at home', hideAmount ? '₱•••' : peso(stats.monthSavings), onEspresso),
          _row('Top café', stats.topCafe ?? '—', onEspresso, mono: false),
          _row('Go-to method', stats.topMethod ?? '—', onEspresso, mono: false),
          _row('Longest streak', '${stats.bestStreak} days', onEspresso),
          if (recentBadges.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: onEspresso.withValues(alpha: 0.14))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BADGES EARNED',
                    style: TextStyle(
                      color: onEspresso.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recentBadges.map((b) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: onEspresso.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BeanIcon(size: 12, color: c.amber),
                            const SizedBox(width: 5),
                            Text(b.name, style: TextStyle(color: onEspresso, fontSize: 12.5)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color onEspresso, {bool mono = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: onEspresso.withValues(alpha: 0.14))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: onEspresso.withValues(alpha: 0.7), fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: onEspresso,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}
