import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entry.dart';
import '../providers/cupboard_controller.dart';
import '../providers/services_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/delete_with_undo.dart';
import '../widgets/entry_card.dart';
import 'entry_form_sheet.dart';

/// A single cup, shown full-page like an opened social post — reached by
/// tapping a card in the feed. Editing/deleting live behind the card's own
/// triple-dot menu here too, so this screen and the feed behave identically.
/// The share action captures the same card as a shareable PNG, reusing the
/// Wrapped screen's RepaintBoundary-capture pattern.
class EntryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;
  const EntryDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cupboard = ref.watch(cupboardControllerProvider).valueOrNull;
    final entries = cupboard?.entries;
    final entry = entries?.where((e) => e.id == widget.entryId).firstOrNull;

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
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            onPressed: _sharing ? null : () => _share(entry),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _boundaryKey,
          // A solid background behind the card, captured as part of the same
          // boundary — without it, the Card's margin and rounded corners
          // leave transparent pixels in the shared PNG, which some share
          // targets render as black instead of the app's cream background.
          child: Container(
            color: c.bg,
            padding: const EdgeInsets.all(4),
            child: EntryCard(
              entry: entry,
              hideAmount: cupboard?.settings.hideAmount ?? false,
              onEdit: () => showEntryForm(context, existing: entry),
              // No explicit pop here — deleting flips `entry` to null above on the
              // next rebuild, which already pops. A second pop call racing that
              // one (mid exit-transition) is exactly the kind of thing that trips
              // Navigator/Element assertions, so there's deliberately only one path.
              onDelete: () => deleteEntryWithUndo(context, ref, entry.id),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share(Entry entry) async {
    setState(() => _sharing = true);
    final title = entry.kind == EntryKind.home
        ? (entry.method ?? 'Home brew')
        : (entry.venueName ?? 'Away');
    try {
      await ref.read(shareServiceProvider).shareImage(
            boundaryKey: _boundaryKey,
            fallbackText: '$title, logged on Tasa ☕',
            subject: 'A cup from Tasa',
          );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
