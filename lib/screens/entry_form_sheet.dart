import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../logic/constants.dart';
import '../logic/date_utils.dart';
import '../models/entry.dart';
import '../providers/cupboard_controller.dart';
import '../providers/derived_providers.dart';
import '../providers/services_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/bean_icon.dart';
import '../widgets/delete_with_undo.dart';

Future<void> showEntryForm(BuildContext context, {Entry? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EntryFormSheet(existing: existing),
  );
}

class EntryFormSheet extends ConsumerStatefulWidget {
  final Entry? existing;
  const EntryFormSheet({super.key, this.existing});

  @override
  ConsumerState<EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends ConsumerState<EntryFormSheet> {
  late EntryKind _kind;
  VenueTag _venueTag = VenueTag.cafe;
  final _venueNameCtrl = TextEditingController();
  final _venueNameFocus = FocusNode();
  String _method = kBrewMethods.first;
  final _methodOtherCtrl = TextEditingController();
  late DateTime _date;
  final _priceCtrl = TextEditingController();
  bool _free = false;
  DayPart? _timeOfDay;
  int _rating = 0;
  final List<String> _flavors = [];
  Roast? _roast;
  final _captionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _photoPath;
  bool _saving = false;
  bool _showAdvanced = false;

  Entry? get existing => widget.existing;
  bool get isEditing => existing != null;

  @override
  void initState() {
    super.initState();
    final e = existing;
    _kind = e?.kind ?? EntryKind.home;
    _venueTag = e?.venueTag ?? VenueTag.cafe;
    _venueNameCtrl.text = e?.venueName ?? '';
    final m = e?.method;
    if (m != null && !kBrewMethods.contains(m)) {
      _method = '__other';
      _methodOtherCtrl.text = m;
    } else {
      _method = m ?? kBrewMethods.first;
    }
    _date = e?.date ?? todayDate();
    _priceCtrl.text = e?.price != null ? e!.price!.round().toString() : '';
    _free = e?.free ?? false;
    _timeOfDay = e?.timeOfDay;
    _rating = e?.rating ?? 0;
    _flavors.addAll(e?.flavors ?? const []);
    _roast = e?.roast;
    _captionCtrl.text = e?.caption ?? '';
    _notesCtrl.text = e?.notes ?? '';
    _photoPath = e?.photoPath;
    // If an entry already has any of the "advanced" fields set (editing a
    // cup logged before this toggle existed, or by a power user), start
    // expanded so nothing already-filled-in is hidden from view.
    _showAdvanced = _free || _timeOfDay != null || _roast != null || _flavors.isNotEmpty;
  }

  @override
  void dispose() {
    _venueNameCtrl.dispose();
    _venueNameFocus.dispose();
    _methodOtherCtrl.dispose();
    _priceCtrl.dispose();
    _captionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final imageService = ref.read(imageServiceProvider);
    final path = await imageService.pickAndCompress(source: source);
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final method = _method == '__other'
        ? (_methodOtherCtrl.text.trim().isEmpty ? 'Other' : _methodOtherCtrl.text.trim())
        : _method;
    final rawPrice = double.tryParse(_priceCtrl.text);
    final fallbackCpc = _kind == EntryKind.home
        ? ref.read(cupboardControllerProvider).valueOrNull?.beanProfile.costPerCup
        : null;
    final price = _free ? 0.0 : (rawPrice ?? fallbackCpc)?.clamp(0, 999999).toDouble();

    var entry = Entry(
      id: existing?.id ?? Entry.newId(),
      kind: _kind,
      date: _date,
      method: method,
      price: price,
      free: _free,
      rating: _rating,
      caption: _captionCtrl.text.trim().isEmpty ? null : _captionCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      photoPath: _photoPath,
      timeOfDay: _timeOfDay,
      flavors: List.of(_flavors),
      roast: _roast,
      isSample: false,
    );
    if (_kind == EntryKind.away) {
      final venueName = _venueNameCtrl.text.trim();
      entry = entry.copyWith(
        venueTag: _venueTag,
        venueName: venueName.isEmpty ? _venueTag.label : venueName,
      );
    }

    try {
      await ref
          .read(cupboardControllerProvider.notifier)
          .saveEntry(entry, isNew: !isEditing);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save — try again.")),
        );
      }
      return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final id = existing?.id;
    if (id == null) return;
    await deleteEntryWithUndo(context, ref, id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // Without this, the DraggableScrollableSheet sizes itself against the
    // full screen height regardless of the keyboard, so its lower portion
    // (Notes, Photo, "More options", the action buttons) ends up rendered
    // underneath the keyboard instead of being scrolled into view above it.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEditing ? 'Edit cup' : 'Log a cup',
                            style: Theme.of(context).textTheme.headlineSmall),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _segmentedKind(c),
                    if (_kind == EntryKind.away) ...[
                      const SizedBox(height: 14),
                      _venueFields(),
                    ],
                    const SizedBox(height: 14),
                    _methodAndDate(),
                    const SizedBox(height: 14),
                    _priceField(c),
                    const SizedBox(height: 14),
                    _label('Rating'),
                    BeanRatingPicker(
                      rating: _rating,
                      color: c.amber,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                    const SizedBox(height: 14),
                    _label('Caption (optional)'),
                    TextField(
                      controller: _captionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'A quick line for the feed'),
                    ),
                    const SizedBox(height: 14),
                    _label('Notes (optional)'),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      minLines: 2,
                      decoration: const InputDecoration(
                          hintText: 'What did you think? How did it make you feel?'),
                    ),
                    const SizedBox(height: 14),
                    _photoField(c),
                    const SizedBox(height: 16),
                    _advancedSection(c),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (isEditing)
                          TextButton(
                            onPressed: _saving ? null : _delete,
                            style: TextButton.styleFrom(foregroundColor: c.danger),
                            child: const Text('Delete'),
                          ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? 'Saving…' : 'Save cup'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.inkSoft)),
      );

  Widget _segmentedKind(AppColors c) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _segButton('Home', _kind == EntryKind.home, () => setState(() => _kind = EntryKind.home), c),
          _segButton('Away', _kind == EntryKind.away, () => setState(() => _kind = EntryKind.away), c),
        ],
      ),
    );
  }

  Widget _segButton(String label, bool active, VoidCallback onTap, AppColors c) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: active ? c.ink : c.surface,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: active ? c.bg : c.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _venueFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Where'),
              DropdownButtonFormField<VenueTag>(
                initialValue: _venueTag,
                isExpanded: true,
                items: VenueTag.values
                    .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                    .toList(),
                onChanged: (v) => setState(() => _venueTag = v ?? VenueTag.cafe),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Name'),
              Autocomplete<String>(
                // Reuses our own controller directly — no manual text mirroring
                // between it and an internally-created one, which previously
                // reset the cursor to the end on every unrelated rebuild.
                textEditingController: _venueNameCtrl,
                focusNode: _venueNameFocus,
                optionsBuilder: (v) {
                  if (v.text.isEmpty) return const Iterable.empty();
                  return ref.read(venueNamesProvider).where(
                      (n) => n.toLowerCase().contains(v.text.toLowerCase()));
                },
                fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                  return TextField(
                    controller: ctrl,
                    focusNode: focusNode,
                    decoration: const InputDecoration(hintText: 'e.g. Yardstick Katipunan'),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _methodAndDate() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Method / drink'),
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                items: [
                  ...kBrewMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                  const DropdownMenuItem(value: '__other', child: Text('Other…')),
                ],
                onChanged: (v) => setState(() => _method = v ?? kBrewMethods.first),
              ),
              if (_method == '__other') ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _methodOtherCtrl,
                  decoration: const InputDecoration(hintText: 'Name it'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Date'),
              // An InputDecorator (not an OutlinedButton) so this matches the
              // exact height/padding/border of the dropdown next to it —
              // a plain button sits shorter and visibly out of line.
              InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = dateOnly(picked));
                },
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Text('${_date.month}/${_date.day}/${_date.year}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceField(AppColors c) {
    final cpc = ref.read(cupboardControllerProvider).valueOrNull?.beanProfile.costPerCup;
    final isHome = _kind == EntryKind.home;
    final fieldHint = isHome && cpc != null ? '≈ ${cpc.round()}' : null;
    final helperText = isHome
        ? (cpc != null
            ? 'Your usual home-brew cost — type today\'s price, or leave blank to use it.'
            : 'No bean profile set yet — enter a rough per-cup cost.')
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Price (₱)'),
        TextField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          enabled: !_free,
          decoration: InputDecoration(hintText: fieldHint),
        ),
        if (helperText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(helperText, style: TextStyle(fontSize: 12, color: c.inkFaint)),
          ),
      ],
    );
  }

  /// Time of day, free/gifted, flavor notes, and roast are all optional
  /// categorization that a casual "just log the cup" user doesn't need to
  /// see every time — folded behind a disclosure so the default form reads
  /// as short and quick, while still being one tap away for anyone who
  /// wants the detail.
  Widget _advancedSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: c.inkSoft,
                ),
                const SizedBox(width: 4),
                Text(
                  _showAdvanced ? 'Fewer options' : 'More options',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.inkSoft),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _showAdvanced ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Time of day'),
                          DropdownButtonFormField<DayPart?>(
                            initialValue: _timeOfDay,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Optional')),
                              ...DayPart.values
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                            ],
                            onChanged: (v) => setState(() => _timeOfDay = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Material(transparency): the sheet's own background decoration
                // otherwise catches this tile's ink/splash paint and Flutter
                // flags it as invisible.
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    value: _free,
                    onChanged: (v) => setState(() => _free = v ?? false),
                    title: const Text('Free / gifted', style: TextStyle(fontSize: 13.5)),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                const SizedBox(height: 8),
                _flavorAndRoast(c),
              ],
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  /// Built-in tags + previously-typed custom ones, plus whatever's already
  /// selected on this entry (so a brand-new custom tag still shows as a chip
  /// before it's ever been saved anywhere).
  List<String> _flavorChipOptions() {
    final suggestions = ref.watch(flavorSuggestionsProvider);
    return {...suggestions, ..._flavors}.toList();
  }

  Future<void> _addCustomFlavor() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CustomFlavorDialog(),
    );
    final flavor = result?.trim() ?? '';
    if (flavor.isEmpty) return;
    setState(() {
      if (!_flavors.contains(flavor)) _flavors.add(flavor);
    });
  }

  Widget _flavorAndRoast(AppColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Flavor notes (optional)'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._flavorChipOptions().map((f) {
                    final active = _flavors.contains(f);
                    return FilterChip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      selected: active,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _flavors.add(f);
                        } else {
                          _flavors.remove(f);
                        }
                      }),
                      selectedColor: c.ink,
                      labelStyle: TextStyle(color: active ? c.bg : c.ink),
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.line),
                    );
                  }),
                  ActionChip(
                    avatar: Icon(Icons.add, size: 15, color: c.inkSoft),
                    label: const Text('Custom', style: TextStyle(fontSize: 12)),
                    backgroundColor: c.surface,
                    side: BorderSide(color: c.line, style: BorderStyle.solid),
                    onPressed: _addCustomFlavor,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Roast (optional)'),
              DropdownButtonFormField<Roast?>(
                initialValue: _roast,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...Roast.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))),
                ],
                onChanged: (v) => setState(() => _roast = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoField(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Photo (optional)'),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Camera'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _pickPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Gallery'),
            ),
            if (_photoPath != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: c.danger),
                onPressed: () => setState(() => _photoPath = null),
              ),
            ],
          ],
        ),
        if (_photoPath != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_photoPath!),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }
}

/// Its own widget (rather than a controller built inline in a method) so the
/// TextEditingController is disposed by this dialog's own State.dispose() —
/// which Flutter calls only once its exit route has actually finished
/// unmounting. Disposing it manually right after `showDialog` returns races
/// the route's exit transition and crashes with "TextEditingController used
/// after being disposed."
class _CustomFlavorDialog extends StatefulWidget {
  const _CustomFlavorDialog();

  @override
  State<_CustomFlavorDialog> createState() => _CustomFlavorDialogState();
}

class _CustomFlavorDialogState extends State<_CustomFlavorDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a flavor note'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        decoration: const InputDecoration(hintText: 'e.g. Ube, Brown sugar'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
