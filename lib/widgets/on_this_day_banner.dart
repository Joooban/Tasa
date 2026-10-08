import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../models/entry.dart';
import '../theme/app_colors.dart';
import 'bean_icon.dart';

/// A single resurfaced memory at the top of the feed — "On this day" from a
/// past year. Dismissible for the current viewing only (resets next app
/// open); nothing is persisted, so it never silently disappears forever.
class OnThisDayBanner extends StatefulWidget {
  final List<Entry> memories;
  final ValueChanged<Entry> onTap;

  const OnThisDayBanner({super.key, required this.memories, required this.onTap});

  @override
  State<OnThisDayBanner> createState() => _OnThisDayBannerState();
}

class _OnThisDayBannerState extends State<OnThisDayBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || widget.memories.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final memory = widget.memories.first;
    final yearsAgo = DateTime.now().year - memory.date.year;
    final yearsLabel = yearsAgo == 1 ? '1 year ago' : '$yearsAgo years ago';
    final title = memory.kind == EntryKind.home
        ? (memory.method ?? 'Home brew')
        : (memory.venueName ?? 'Away');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.amber.withValues(alpha: 0.12),
        border: Border.all(color: c.amber.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      // Material(transparency) gives the tile a proper ink-painting ancestor —
      // without it, its splash paints onto whichever distant Material
      // ancestor InkWell finds instead, underneath this Container's own
      // decoration, and never becomes visible (same fix as settings_screen.dart).
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => widget.onTap(memory),
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              BeanIcon(size: 28, color: c.amberInk),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('On this day, $yearsLabel',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: c.amberInk)),
                    const SizedBox(height: 2),
                    Text('$title · ${fmtShortDate(memory.date)}',
                        style: TextStyle(fontSize: 13, color: c.ink)),
                    if (widget.memories.length > 1)
                      Text('+${widget.memories.length - 1} more year(s)',
                          style: TextStyle(fontSize: 11, color: c.inkFaint)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: c.inkFaint),
                onPressed: () => setState(() => _dismissed = true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
