import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../services/version_service.dart';
export '../services/version_service.dart' show VersionInfo;

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final imageServiceProvider = Provider<ImageService>((ref) => ImageService());

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService(ref.watch(databaseServiceProvider)));

final shareServiceProvider = Provider<ShareService>((ref) => ShareService());

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final versionServiceProvider = Provider<VersionService>((ref) => VersionService());

final versionInfoProvider =
    FutureProvider<VersionInfo>((ref) => ref.watch(versionServiceProvider).load());
