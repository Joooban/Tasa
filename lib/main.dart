import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/profile.dart';
import 'providers/cupboard_controller.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_PH');
  runApp(const ProviderScope(child: TasaApp()));
}

class TasaApp extends ConsumerWidget {
  const TasaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(cupboardControllerProvider).valueOrNull?.settings.themeMode;
    return MaterialApp(
      title: 'Tasa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (appThemeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system || null => ThemeMode.system,
      },
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(cupboardControllerProvider);
    return asyncState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
      ),
      data: (state) => state.settings.hasOnboarded ? const RootShell() : const OnboardingScreen(),
    );
  }
}
