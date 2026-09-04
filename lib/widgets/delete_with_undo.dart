import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cupboard_controller.dart';

/// Deletes an entry and offers a brief "Undo" — shared by the entry form's
/// delete button and each feed card's own menu, so the behavior (and the
/// snackbar) is identical no matter where the delete was triggered from.
Future<void> deleteEntryWithUndo(BuildContext context, WidgetRef ref, String id) async {
  final removed = await ref.read(cupboardControllerProvider.notifier).deleteEntry(id);
  if (removed == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Cup deleted.'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => ref.read(cupboardControllerProvider.notifier).restoreEntry(removed),
      ),
    ),
  );
}
