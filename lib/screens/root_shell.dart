import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cupboard_controller.dart';
import '../providers/derived_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/streak_icon.dart';
import 'badges_screen.dart';
import 'cupboard_screen.dart';
import 'entry_form_sheet.dart';
import 'settings_screen.dart';
import 'streak_sheet.dart';
import 'wrapped_screen.dart';

enum _Tab { cupboard, wrapped, badges, settings }

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  _Tab _tab = _Tab.cupboard;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final asyncState = ref.watch(cupboardControllerProvider);

    ref.listen(cupboardControllerProvider, (prev, next) {
      final toasts = next.valueOrNull?.toastQueue ?? const [];
      if (toasts.isNotEmpty) {
        final message = toasts.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          ref.read(cupboardControllerProvider.notifier).consumeToast(message);
        });
      }
    });

    return Scaffold(
      backgroundColor: c.bg,
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Something went wrong loading your cupboard.\n$e',
                textAlign: TextAlign.center, style: TextStyle(color: c.danger)),
          ),
        ),
        data: (state) => SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(context, c, state.profile.name, ref.watch(statsProvider)?.streak ?? 0),
              Expanded(
                child: IndexedStack(
                  index: _tab.index,
                  children: const [
                    CupboardScreen(),
                    WrappedScreen(),
                    BadgesScreen(),
                    SettingsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(c),
    );
  }

  Widget _topBar(BuildContext context, AppColors c, String name, int streak) {
    final tagline = name.trim().isNotEmpty ? 'hey, ${name.trim()} ☕' : 'cups, remembered';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Tasa', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 10),
              Text(tagline, style: TextStyle(color: c.inkSoft, fontSize: 13)),
            ],
          ),
          GestureDetector(
            onTap: () => showStreakSheet(context),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreakIcon(size: 15, color: c.amberInk),
                  const SizedBox(width: 5),
                  Text('$streak-day streak',
                      style: TextStyle(fontSize: 13, color: c.amberInk, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav(AppColors c) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 62,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.92),
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x1A2B1D14), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Row(
            children: [
              _navItem(c, Icons.inventory_2_outlined, 'Cupboard', _Tab.cupboard),
              _navItem(c, Icons.auto_awesome_outlined, 'Wrapped', _Tab.wrapped),
              _fab(c),
              _navItem(c, Icons.military_tech_outlined, 'Badges', _Tab.badges),
              _navItem(c, Icons.settings_outlined, 'Settings', _Tab.settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(AppColors c, IconData icon, String label, _Tab tab) {
    final active = _tab == tab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _tab = tab),
        child: Container(
          decoration: BoxDecoration(
            color: active ? c.amber.withValues(alpha: 0.16) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: active ? c.amberInk : c.inkFaint),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: active ? c.amberInk : c.inkFaint)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fab(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Transform.translate(
        offset: const Offset(0, -13),
        child: SizedBox(
          width: 50,
          height: 50,
          child: FloatingActionButton(
            heroTag: 'add-entry',
            backgroundColor: c.amber,
            foregroundColor: const Color(0xFF241505),
            elevation: 4,
            onPressed: () => showEntryForm(context),
            child: const Icon(Icons.add, size: 23),
          ),
        ),
      ),
    );
  }
}
