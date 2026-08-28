import 'dart:math';

final Random _rnd = Random();

/// 生成本地唯一 ID（UUID v4 格式），供 Place / Collection 主键使用。
/// 本地单用户场景只需保证唯一性，无需引入外部 uuid 依赖。
String generateId() {
  final bytes = List<int>.generate(16, (_) => _rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// 当前时间戳（ISO 8601，本地时间）。
String nowIso8601() => DateTime.now().toIso8601String();
