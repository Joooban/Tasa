import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cupboard_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/bean_icon.dart';

/// A short first-run flow: what Tasa does, the philosophy stated up front
/// (streaks track showing up, not drinking more), then optional name entry.
/// Lands on a Cupboard pre-loaded with clearly-marked sample entries.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameCtrl = TextEditingController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    await ref.read(cupboardControllerProvider.notifier).completeOnboarding(name: _nameCtrl.text);
  }

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _brandSlide(c),
                  _slide(
                    c,
                    icon: Icons.favorite_outline,
                    title: 'Streaks track showing up',
                    body: 'Not drinking more. Logging a cup — or logging "no coffee today" — '
                        'keeps your streak alive. Nothing here rewards you for drinking extra.',
                  ),
                  _namePage(c),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? c.amber : c.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishing ? null : _next,
                      child: Text(_page == 2 ? "Let's go" : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The first slide doubles as the app's brand intro — the actual logo
  /// mark + wordmark, matching the design team's splash mockups, instead of
  /// a generic Material icon like the other slides use.
  Widget _brandSlide(AppColors c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            isDark ? 'assets/icon_mark_dark.png' : 'assets/icon_mark.png',
            height: 96,
          ),
          const SizedBox(height: 16),
          Text('TASA', style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 4)),
          const SizedBox(height: 6),
          Text('cups, remembered', style: TextStyle(fontSize: 15, color: c.danger)),
          const SizedBox(height: 22),
          Text(
            'Tasa is a lightweight coffee-life tracker — brews, café runs, and '
            'spend, kept as a record you can look back on.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: c.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _slide(AppColors c, {required IconData icon, required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: c.amber),
          const SizedBox(height: 24),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: c.inkSoft, height: 1.5)),
        ],
      ),
    );
  }

  Widget _namePage(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BeanIcon(size: 48, color: Color(0xFFC98A3A)),
          const SizedBox(height: 24),
          Text('What should we call you?',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Optional — just for your Wrapped card and greeting. Nothing leaves this device.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.inkSoft)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            maxLength: 24,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'e.g. John', counterText: ''),
          ),
        ],
      ),
    );
  }
}
