import 'package:package_info_plus/package_info_plus.dart';

/// Bump this alongside the version in pubspec.yaml every time a new signed APK
/// is cut, so the in-app "a newer version is available" notice stays accurate.
/// There's no store and no backend, so this is a manually-maintained constant
/// rather than a network check — keeps the app fully offline-capable.
const String kLatestKnownVersion = '0.1.0';
const String kDownloadLinkPlaceholder = 'the Tasa Google Drive link';

class VersionInfo {
  final String currentVersion;
  final String currentBuildNumber;
  final bool updateAvailable;

  const VersionInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.updateAvailable,
  });
}

class VersionService {
  Future<VersionInfo> load() async {
    final info = await PackageInfo.fromPlatform();
    return VersionInfo(
      currentVersion: info.version,
      currentBuildNumber: info.buildNumber,
      updateAvailable: _isOlder(info.version, kLatestKnownVersion),
    );
  }

  bool _isOlder(String current, String latest) {
    final c = current.split('.').map(int.tryParse).toList();
    final l = latest.split('.').map(int.tryParse).toList();
    for (var i = 0; i < l.length; i++) {
      final cv = i < c.length ? (c[i] ?? 0) : 0;
      final lv = l[i] ?? 0;
      if (cv != lv) return cv < lv;
    }
    return false;
  }
}
