import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'collection_repository.dart';
import 'sync_service.dart';

/// 坚果云自动同步：App 进入后台时，若为 WiFi 且已配置 WebDAV，则全量备份 JSON。
/// 30 秒防抖；失败静默忽略，下次再试（PRD §5.2）。
class SyncManager with WidgetsBindingObserver {
  final CollectionRepository _repo = CollectionRepository();
  DateTime? _lastSyncAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      syncIfNeeded();
    }
  }

  Future<void> syncIfNeeded() async {
    final now = DateTime.now();
    if (_lastSyncAt != null &&
        now.difference(_lastSyncAt!) < const Duration(seconds: 30)) {
      return;
    }
    _lastSyncAt = now;

    try {
      // 仅 Wi-Fi 时同步
      final results = await Connectivity().checkConnectivity();
      if (!results.contains(ConnectivityResult.wifi)) return;

      // 读 WebDAV 配置；未配置则跳过
      final url = await _repo.getSetting('webdav_url');
      if (url == null || url.isEmpty) return;
      final user = await _repo.getSetting('webdav_username') ?? '';
      final pass = await _repo.getSetting('webdav_password') ?? '';

      // 全量导出并上传（失败静默忽略）
      final service = SyncService(url: url, username: user, password: pass);
      final places = await _repo.getAllPlaces();
      final views = await _repo.getCollectionViews();
      final collections = views.map((v) => v.collection).toList();
      final json = service.buildBackupJson(places, collections);
      await service.upload(json);
    } catch (_) {
      // 静默忽略，下次后台重试
    }
  }
}
