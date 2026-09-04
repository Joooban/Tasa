import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cupboard_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/delete_with_undo.dart';
import '../widgets/entry_card.dart';
import 'entry_form_sheet.dart';

/// A single cup, shown full-page like an opened social post — reached by
/// tapping a card in the feed. Editing/deleting live behind the card's own
/// triple-dot menu here too, so this screen and the feed behave identically.
class EntryDetailScreen extends ConsumerWidget {
  final String entryId;
  const EntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final entries = ref.watch(cupboardControllerProvider).valueOrNull?.entries;
    final entry = entries?.where((e) => e.id == entryId).firstOrNull;

    // Deleted (including via this screen's own menu) while we're looking at it.
    if (entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return Scaffold(backgroundColor: c.bg, body: const SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: const Text('Cup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: EntryCard(
          entry: entry,
          onEdit: () => showEntryForm(context, existing: entry),
          // No explicit pop here — deleting flips `entry` to null above on the
          // next rebuild, which already pops. A second pop call racing that
          // one (mid exit-transition) is exactly the kind of thing that trips
          // Navigator/Element assertions, so there's deliberately only one path.
          onDelete: () => deleteEntryWithUndo(context, ref, entry.id),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
