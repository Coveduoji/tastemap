import 'dart:convert';
import 'dart:io';

import '../config.dart';
import '../models/primary_tag.dart';

/// 附近地点（来自高德周边搜索）。
class Poi {
  final String name;
  final PrimaryTag tag;
  final String addr;
  final String city;
  final String distance;
  final double latitude;
  final double longitude;

  const Poi({
    required this.name,
    required this.tag,
    required this.addr,
    this.city = '',
    required this.distance,
    required this.latitude,
    required this.longitude,
  });
}

/// 高德周边搜索（真实附近地点，按距离排序）。
class PoiSearchService {
  /// 周边搜索：当前位置附近的真实地点，按距离排序。
  static Future<List<Poi>> searchNearby(double lat, double lng) {
    return _search(
      'https://restapi.amap.com/v3/place/around'
      '?key=${AppConfig.amapWebApiKey}'
      '&location=$lng,$lat'
      '&radius=1000'
      '&sortrule=distance'
      '&offset=10'
      '&page=1',
      lat,
      lng,
    );
  }

  /// 关键词搜索：全国范围按名称搜索（不限制当前位置，便于异地收藏、以后去）。
  static Future<List<Poi>> searchByName(String keyword, double lat, double lng) {
    final kw = Uri.encodeComponent(keyword);
    return _search(
      'https://restapi.amap.com/v3/place/text'
      '?key=${AppConfig.amapWebApiKey}'
      '&keywords=$kw'
      '&offset=20'
      '&page=1',
      lat,
      lng,
    );
  }

  static Future<List<Poi>> _search(String url, double lat, double lng) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(url));
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
              city: _readStr(m['cityname']),
              distance: _formatDistance(_readStr(m['distance'])),
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

  /// 逆地理编码：坐标转城市 + 国家（收藏保存时用，填充 Place.city / Place.country）。
  static Future<({String? city, String? country})> reverseGeocode(
      double lat, double lng) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(
        'https://restapi.amap.com/v3/geocode/regeo'
        '?key=${AppConfig.amapWebApiKey}&location=$lng,$lat',
      ));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final component = (decoded['regeocode']
              as Map<String, dynamic>?)?['addressComponent']
          as Map<String, dynamic>?;
      final province = _readStr(component?['province']);
      final city = _readStr(component?['city']);
      final country = _readStr(component?['country']);
      return (
        city: city.isNotEmpty ? city : (province.isNotEmpty ? province : null),
        country: country.isNotEmpty ? country : null,
      );
    } catch (_) {
      return (city: null, country: null);
    }
  }

  static String _formatDistance(String meters) {
    final m = int.tryParse(meters) ?? 0;
    if (m <= 0) return ''; // 全国搜索无距离时返回空
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
