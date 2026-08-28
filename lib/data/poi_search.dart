import 'dart:convert';
import 'dart:io';

import '../config.dart';
import '../models/primary_tag.dart';

/// 附近地点（来自高德周边搜索）。
class Poi {
  final String name;
  final PrimaryTag tag;
  final String addr;
  final String distance;
  final double latitude;
  final double longitude;

  const Poi({
    required this.name,
    required this.tag,
    required this.addr,
    required this.distance,
    required this.latitude,
    required this.longitude,
  });
}

/// 高德周边搜索（真实附近地点，按距离排序）。
class PoiSearchService {
  static Future<List<Poi>> searchNearby(double lat, double lng) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(
        'https://restapi.amap.com/v3/place/around'
        '?key=${AppConfig.amapWebApiKey}'
        '&location=$lng,$lat'
        '&radius=1000'
        '&sortrule=distance'
        '&offset=10'
        '&page=1',
      ));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (decoded['status'] != '1') return const [];
      final pois = decoded['pois'] as List? ?? const [];
      return pois
          .map((p) {
            final m = p as Map<String, dynamic>;
            final loc = (m['location'] as String? ?? '').split(',');
            final name = m['name'] as String? ?? '';
            if (name.isEmpty) return null;
            return Poi(
              name: name,
              tag: _tagFromAmapType(m['type'] as String? ?? ''),
              addr: _readStr(m['address']),
              distance: _formatDistance(m['distance'] as String? ?? ''),
              latitude: double.tryParse(loc.length > 1 ? loc[1] : '') ?? lat,
              longitude: double.tryParse(loc.isNotEmpty ? loc[0] : '') ?? lng,
            );
          })
          .whereType<Poi>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String _readStr(dynamic v) {
    if (v is String && v.isNotEmpty) return v;
    if (v is List && v.isNotEmpty) return v.first.toString();
    return '';
  }

  static String _formatDistance(String meters) {
    final m = int.tryParse(meters) ?? 0;
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}km';
    return '${m}m';
  }

  /// 高德 type 是「大类;中类;小类」的层级，按关键词映射到一级标签。
  static PrimaryTag _tagFromAmapType(String type) {
    if (type.contains('咖啡')) return PrimaryTag.coffee;
    if (type.contains('酒店') ||
        type.contains('宾馆') ||
        type.contains('住宿')) {
      return PrimaryTag.hotel;
    }
    if (type.contains('风景') ||
        type.contains('名胜') ||
        type.contains('公园') ||
        type.contains('景点') ||
        type.contains('博物馆') ||
        type.contains('寺') ||
        type.contains('教堂')) {
      return PrimaryTag.sight;
    }
    if (type.contains('酒吧') || type.contains('夜店')) return PrimaryTag.bar;
    return PrimaryTag.food; // 餐饮等默认归为美食
  }
}
