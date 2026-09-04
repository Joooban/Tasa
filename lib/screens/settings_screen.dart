import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/format.dart';
import '../models/profile.dart';
import '../providers/cupboard_controller.dart';
import '../providers/services_providers.dart';
import '../services/version_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _bagPriceCtrl = TextEditingController();
  final _cupsPerBagCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bagPriceCtrl.dispose();
    _cupsPerBagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(cupboardControllerProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    if (!_initialized) {
      _nameCtrl.text = state.profile.name;
      _bagPriceCtrl.text = state.beanProfile.bagPrice.round().toString();
      _cupsPerBagCtrl.text = state.beanProfile.cupsPerBag.toString();
      _initialized = true;
    }

    final sampleCount = state.entries.where((e) => e.isSample).length;
    final cpc = state.beanProfile.costPerCup;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _panel(
          c,
          title: 'Appearance',
          desc: 'Night mode, or follow your system setting.',
          child: SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(value: AppThemeMode.system, label: Text('System')),
              ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
              ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
            ],
            selected: {state.settings.themeMode},
            onSelectionChanged: (selection) => ref
                .read(cupboardControllerProvider.notifier)
                .setThemeMode(selection.first),
          ),
        ),
        _panel(
          c,
          title: 'Profile',
          desc: 'Just for you — used to personalize your Wrapped and greeting. No account, '
              'nothing leaves this device.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. John'),
              ),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(cupboardControllerProvider.notifier).saveProfileName(_nameCtrl.text);
                  if (context.mounted) {
                    final n = _nameCtrl.text.trim();
                    _toast(context, n.isNotEmpty ? 'Saved — hey, $n ☕' : 'Name cleared.');
                  }
                },
                child: const Text('Save name'),
              ),
            ],
          ),
        ),
        _panel(
          c,
          title: 'Bean profile',
          desc: 'Set your bag price once — home-brew cost per cup fills in automatically from '
              'here on.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bagPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bag price (₱)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cupsPerBagCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cups per bag'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                cpc != null
                    ? '≈ ${peso(cpc)} per home-brewed cup'
                    : 'Set both fields to auto-fill home brew cost.',
                style: TextStyle(fontSize: 12, color: c.inkFaint),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(cupboardControllerProvider.notifier).saveBeanProfile(
                        bagPrice: double.tryParse(_bagPriceCtrl.text) ?? 0,
                        cupsPerBag: int.tryParse(_cupsPerBagCtrl.text) ?? 1,
                      );
                  if (context.mounted) _toast(context, 'Bean profile saved.');
                },
                child: const Text('Save bean profile'),
              ),
            ],
          ),
        ),
        _panel(
          c,
          title: 'Sample data',
          desc: 'A few sample cups are in your cupboard so you can see how it feels. They clear '
              'on their own once you log something real — or clear them now.',
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final msg = await ref.read(cupboardControllerProvider.notifier).clearSampleEntries();
                  if (context.mounted) _toast(context, msg);
                },
                child: const Text('Clear sample cups'),
              ),
              Text(
                sampleCount > 0 ? '$sampleCount sample entries in your cupboard' : 'No sample entries remain.',
                style: TextStyle(fontSize: 12, color: c.inkFaint),
              ),
            ],
          ),
        ),
        _panel(
          c,
          title: 'Daily reminder',
          desc: 'A gentle, opt-in nudge once a day. Off by default, easy to disable, never '
              'guilt-toned.',
          // Material(transparency) gives the tile a proper ink-painting ancestor —
          // without it, its background/splash paint onto the panel's own
          // DecoratedBox instead and Flutter flags it as invisible.
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              value: state.settings.notificationsEnabled,
              onChanged: (v) async {
                final notifier = ref.read(cupboardControllerProvider.notifier);
                if (v) {
                  bool granted;
                  try {
                    granted = await ref.read(notificationServiceProvider).requestPermission();
                  } catch (_) {
                    granted = false;
                  }
                  if (!granted) {
                    if (context.mounted) _toast(context, "Notifications weren't allowed — you can turn this on later from system settings.");
                    return;
                  }
                }
                // Scheduling/cancelling the OS-level reminder is best-effort — if the
                // plugin throws for any reason, the switch must still flip and save,
                // or it looks permanently stuck (can't be turned back off) instead of
                // just quietly not having a reminder scheduled.
                try {
                  if (v) {
                    await ref.read(notificationServiceProvider).scheduleDailyReminder();
                  } else {
                    await ref.read(notificationServiceProvider).cancelDailyReminder();
                  }
                } catch (_) {
                  if (context.mounted) {
                    _toast(context, "Saved, but couldn't reach the system notification service — try again if reminders don't behave.");
                  }
                }
                await notifier.setNotificationsEnabled(v);
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me once a day', style: TextStyle(fontSize: 13.5)),
            ),
          ),
        ),
        _panel(
          c,
          title: 'Your data',
          desc: 'Everything lives on this device only. Export a backup before an uninstall or '
              'device change, or move it to a new phone.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () async {
                  try {
                    final path = await ref.read(backupServiceProvider).exportToFile();
                    if (context.mounted) {
                      _toast(context, path != null ? 'Backup saved.' : 'Export cancelled.');
                    }
                  } catch (e) {
                    if (context.mounted) _toast(context, "Couldn't export: $e");
                  }
                },
                child: const Text('Export data'),
              ),
              OutlinedButton(
                onPressed: () async {
                  try {
                    final imported = await ref.read(backupServiceProvider).importFromFile();
                    if (imported) {
                      await ref.read(cupboardControllerProvider.notifier).reloadFromDatabase();
                      setState(() => _initialized = false);
                      if (context.mounted) _toast(context, 'Data imported.');
                    }
                  } catch (_) {
                    if (context.mounted) _toast(context, "That didn't look like a valid backup.");
                  }
                },
                child: const Text('Import data'),
              ),
            ],
          ),
        ),
        _panel(
          c,
          title: 'Feedback',
          desc: 'Something broken, or an idea? A real reply beats an analytics dashboard.',
          child: OutlinedButton(
            onPressed: () async {
              final uri = Uri.parse(
                  'mailto:jvanmorden@gmail.com?subject=${Uri.encodeComponent('Tasa feedback')}');
              bool launched;
              try {
                launched = await launchUrl(uri);
              } catch (_) {
                launched = false;
              }
              if (!launched && context.mounted) {
                _toast(context, 'No email app found — reach us at jvanmorden@gmail.com');
              }
            },
            child: const Text('Send feedback'),
          ),
        ),
        Consumer(
          builder: (context, ref, _) {
            final versionAsync = ref.watch(versionInfoProvider);
            return versionAsync.when(
              data: (v) => _versionPanel(c, v),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }

  Widget _versionPanel(AppColors c, VersionInfo v) {
    return _panel(
      c,
      title: 'About',
      desc: 'Tasa isn\'t on an app store — updates come as a new signed APK.',
      child: Text(
        v.updateAvailable
            ? 'You have v${v.currentVersion}. A newer version is available — check $kDownloadLinkPlaceholder.'
            : 'v${v.currentVersion} — you\'re up to date.',
        style: TextStyle(fontSize: 13, color: c.inkSoft),
      ),
    );
  }

  Widget _panel(AppColors c, {required String title, required String desc, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 13, color: c.inkSoft)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
