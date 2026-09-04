/// Local, self-entered display name. Not an account — nothing leaves the device.
class Profile {
  final String name;

  const Profile({this.name = ''});

  Profile copyWith({String? name}) => Profile(name: name ?? this.name);

  Map<String, Object?> toMap() => {'id': 1, 'name': name};

  factory Profile.fromMap(Map<String, Object?> m) => Profile(name: m['name'] as String? ?? '');
}

/// Bag price + cups-per-bag, used to auto-fill home-brew cost per cup.
class BeanProfile {
  final double bagPrice;
  final int cupsPerBag;

  const BeanProfile({this.bagPrice = 450, this.cupsPerBag = 16});

  double? get costPerCup => (bagPrice > 0 && cupsPerBag > 0) ? bagPrice / cupsPerBag : null;

  BeanProfile copyWith({double? bagPrice, int? cupsPerBag}) => BeanProfile(
        bagPrice: bagPrice ?? this.bagPrice,
        cupsPerBag: cupsPerBag ?? this.cupsPerBag,
      );

  Map<String, Object?> toMap() => {'id': 1, 'bag_price': bagPrice, 'cups_per_bag': cupsPerBag};

  factory BeanProfile.fromMap(Map<String, Object?> m) => BeanProfile(
        bagPrice: (m['bag_price'] as num?)?.toDouble() ?? 450,
        cupsPerBag: (m['cups_per_bag'] as num?)?.toInt() ?? 16,
      );
}

/// User's appearance preference — kept as our own enum (not Flutter's
/// ThemeMode) so this model file stays plain data, no framework import.
enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  String get id => name;
  String get label => switch (this) {
        AppThemeMode.system => 'System',
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
      };
  static AppThemeMode fromId(String? id) {
    for (final m in AppThemeMode.values) {
      if (m.name == id) return m;
    }
    return AppThemeMode.system;
  }
}

/// App-wide preferences and Rain Check (streak freeze) bookkeeping.
class AppSettings {
  final bool hideAmount;
  final bool seenRealEntry;
  final int freezeBank;
  final int freezeMilestone;
  final bool notificationsEnabled;
  final bool hasOnboarded;
  final AppThemeMode themeMode;

  const AppSettings({
    this.hideAmount = false,
    this.seenRealEntry = false,
    this.freezeBank = 0,
    this.freezeMilestone = 0,
    this.notificationsEnabled = false,
    this.hasOnboarded = false,
    this.themeMode = AppThemeMode.system,
  });

  AppSettings copyWith({
    bool? hideAmount,
    bool? seenRealEntry,
    int? freezeBank,
    int? freezeMilestone,
    bool? notificationsEnabled,
    bool? hasOnboarded,
    AppThemeMode? themeMode,
  }) =>
      AppSettings(
        hideAmount: hideAmount ?? this.hideAmount,
        seenRealEntry: seenRealEntry ?? this.seenRealEntry,
        freezeBank: freezeBank ?? this.freezeBank,
        freezeMilestone: freezeMilestone ?? this.freezeMilestone,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        hasOnboarded: hasOnboarded ?? this.hasOnboarded,
        themeMode: themeMode ?? this.themeMode,
      );

  Map<String, Object?> toMap() => {
        'id': 1,
        'hide_amount': hideAmount ? 1 : 0,
        'seen_real_entry': seenRealEntry ? 1 : 0,
        'freeze_bank': freezeBank,
        'freeze_milestone': freezeMilestone,
        'notifications_enabled': notificationsEnabled ? 1 : 0,
        'has_onboarded': hasOnboarded ? 1 : 0,
        'theme_mode': themeMode.id,
      };

  factory AppSettings.fromMap(Map<String, Object?> m) => AppSettings(
        hideAmount: (m['hide_amount'] as int? ?? 0) == 1,
        seenRealEntry: (m['seen_real_entry'] as int? ?? 0) == 1,
        freezeBank: m['freeze_bank'] as int? ?? 0,
        freezeMilestone: m['freeze_milestone'] as int? ?? 0,
        notificationsEnabled: (m['notifications_enabled'] as int? ?? 0) == 1,
        hasOnboarded: (m['has_onboarded'] as int? ?? 0) == 1,
        themeMode: AppThemeModeX.fromId(m['theme_mode'] as String?),
      );
}
