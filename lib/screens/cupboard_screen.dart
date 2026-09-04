import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entry.dart';
import '../providers/cupboard_controller.dart';
import '../providers/derived_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/delete_with_undo.dart';
import '../widgets/entry_card.dart';
import 'entry_detail_screen.dart';
import 'entry_form_sheet.dart';

/// The core log of every cup — home-brewed or bought away. The primary way a
/// user "shows off" their cupboard when sharing screenshots.
class CupboardScreen extends ConsumerWidget {
  const CupboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(cupboardControllerProvider).valueOrNull;
    final filter = ref.watch(cupboardFilterProvider);
    if (state == null) return const SizedBox.shrink();

    var entries = List<Entry>.from(state.entries)
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    if (filter != CupboardFilter.all) {
      final kind = filter == CupboardFilter.home ? EntryKind.home : EntryKind.away;
      entries = entries.where((e) => e.kind == kind).toList();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              spacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _filterChip(context, ref, 'All', CupboardFilter.all),
                    const SizedBox(width: 6),
                    _filterChip(context, ref, 'Home', CupboardFilter.home),
                    const SizedBox(width: 6),
                    _filterChip(context, ref, 'Away', CupboardFilter.away),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final msg =
                            await ref.read(cupboardControllerProvider.notifier).repeatYesterday();
                        if (context.mounted) _toast(context, msg);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Repeat yesterday', style: TextStyle(fontSize: 12.5)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final msg = await ref.read(cupboardControllerProvider.notifier).skipToday();
                        if (context.mounted) _toast(context, msg);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('No coffee today', style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (entries.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: c.line, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No cups here yet. Tap the + below to start your cupboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.inkSoft),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                if (e.kind == EntryKind.skip) return EntryCard(entry: e);
                return EntryCard(
                  entry: e,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: e.id)),
                  ),
                  onEdit: () => showEntryForm(context, existing: e),
                  onDelete: () => deleteEntryWithUndo(context, ref, e.id),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _filterChip(BuildContext context, WidgetRef ref, String label, CupboardFilter value) {
    final c = context.colors;
    final active = ref.watch(cupboardFilterProvider) == value;
    return GestureDetector(
      onTap: () => ref.read(cupboardFilterProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.ink : c.surface,
          border: Border.all(color: active ? c.ink : c.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? c.bg : c.inkSoft,
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
