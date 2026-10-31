import 'dart:convert';
import 'dart:typed_data';

import 'package:webdav_client/webdav_client.dart';

import '../models/collection.dart';
import '../models/place.dart';

/// 坚果云 WebDAV 云同步：JSON 全量备份 / 恢复（PRD §5.2）。
class SyncService {
  static const String backupPath = '/TasteMap/backup.json';

  final String url;
  final String username;
  final String password;

  const SyncService({
    required this.url,
    required this.username,
    required this.password,
  });

  /// 构建全量备份 JSON（place + collection 两张表）。
  String buildBackupJson(List<Place> places, List<Collection> collections) {
    return jsonEncode({
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'places': places.map((p) => p.toMap()).toList(),
      'collections': collections.map((c) => c.toMap()).toList(),
    });
  }

  /// 解析备份 JSON。
  ({List<Place> places, List<Collection> collections}) parseBackupJson(
    String json,
  ) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final places = (decoded['places'] as List)
        .map((m) => Place.fromMap((m as Map).cast<String, Object?>()))
        .toList();
    final collections = (decoded['collections'] as List)
        .map((m) => Collection.fromMap((m as Map).cast<String, Object?>()))
        .toList();
    return (places: places, collections: collections);
  }

  Client _client() => newClient(url, user: username, password: password);

  /// 上传备份 JSON（失败返回 false，静默忽略）。
  Future<bool> upload(String json) async {
    try {
      final data = Uint8List.fromList(utf8.encode(json));
      final client = _client();
      await client.mkdirAll('/TasteMap');
      await client.write(backupPath, data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 下载备份 JSON（失败返回 null，静默忽略）。
  Future<String?> download() async {
    try {
      final bytes = await _client().read(backupPath);
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }
}
