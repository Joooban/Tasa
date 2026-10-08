import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../logic/spend_trend.dart';
import '../theme/app_colors.dart';

/// A minimal, dependency-free bar chart — consistent with the rest of the
/// app's hand-rolled visuals (BeanIcon, StreakIcon) rather than pulling in
/// a charting package for one simple view.
class SpendTrendChart extends StatelessWidget {
  final List<MonthSpend> months;

  const SpendTrendChart({super.key, required this.months});

  static const _barAreaHeight = 90.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxSpend = months.fold<double>(0, (a, m) => m.spend > a ? m.spend : a);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: months.map((m) {
          final barHeight = maxSpend > 0
              ? (m.spend / maxSpend * _barAreaHeight).clamp(3.0, _barAreaHeight)
              : 3.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (m.spend > 0)
                  Text(peso(m.spend), style: TextStyle(fontSize: 9, color: c.inkFaint)),
                const SizedBox(height: 4),
                Container(
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: c.amber,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_monthLabel(m.month), style: TextStyle(fontSize: 10, color: c.inkSoft)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // A year marker only on January avoids repeating it on every bar while
  // still disambiguating a Dec→Jan crossing — the one point where two
  // adjacent bars would otherwise read as the same month.
  String _monthLabel(DateTime d) =>
      d.month == 1 ? "${fmtMonthShort(d)} '${(d.year % 100).toString().padLeft(2, '0')}" : fmtMonthShort(d);
}
