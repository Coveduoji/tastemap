import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../config.dart';
import '../models/place.dart';
import '../models/nearby_category.dart';
import '../models/poi_category.dart';

class Poi {
  final String name, id, typeCode, typeDescription, addr, city, distance;
  final String province, district, adcode, phone, hours, rating, cost;
  final String weeklyHours, businessArea, feature, parkingType, floor, alias;
  final List<Poi> children;
  final List<String> photos;
  final double latitude, longitude;
  PoiCategory get category => PoiCategory.fromAmap(typeCode, typeDescription);
  const Poi({
    required this.name,
    this.id = '',
    this.typeCode = '',
    this.typeDescription = '',
    required this.addr,
    this.city = '',
    this.province = '',
    this.district = '',
    this.adcode = '',
    this.phone = '',
    this.hours = '',
    this.rating = '',
    this.cost = '',
    this.photos = const [],
    this.weeklyHours = '',
    this.businessArea = '',
    this.feature = '',
    this.parkingType = '',
    this.floor = '',
    this.alias = '',
    this.children = const [],
    required this.distance,
    required this.latitude,
    required this.longitude,
  });
  factory Poi.fromPlace(Place p) => Poi(
    name: p.name,
    id: p.amapId ?? '',
    addr: p.address ?? '',
    city: p.city ?? '',
    province: p.province ?? '',
    district: p.district ?? '',
    adcode: p.adcode ?? '',
    distance: '',
    latitude: p.latitude,
    longitude: p.longitude,
  );
  factory Poi.fromMap(Map<String, dynamic> m) {
    final location = read(m['location']).split(',');
    final business = m['business'] is Map
        ? m['business'] as Map
        : m['biz_ext'] is Map
        ? m['biz_ext'] as Map
        : const {};
    final photos = m['photos'] is List
        ? (m['photos'] as List)
              .whereType<Map>()
              .map((v) => read(v['url']))
              .where(
                (s) =>
                    Uri.tryParse(s)?.scheme == 'https' ||
                    Uri.tryParse(s)?.scheme == 'http',
              )
              .toList()
        : <String>[];
    final indoor = m['indoor'] is Map
        ? m['indoor'] as Map
        : m['indoor_data'] is Map
        ? m['indoor_data'] as Map
        : const {};
    final childRows = m['children'] is List ? m['children'] as List : const [];
    final meters = int.tryParse(read(m['distance']));
    return Poi(
      name: read(m['name']),
      id: read(m['id']),
      typeCode: read(m['typecode']),
      typeDescription: read(m['type']),
      addr: read(m['address']),
      city: read(m['cityname']),
      province: read(m['pname']),
      district: read(m['adname']),
      adcode: read(m['adcode']),
      phone: read(business['tel']).isNotEmpty
          ? read(business['tel'])
          : read(m['tel']),
      hours: read(business['opentime_today']).isNotEmpty
          ? read(business['opentime_today'])
          : read(business['opentime']).isNotEmpty
          ? read(business['opentime'])
          : read(m['opentime']),
      rating: read(business['rating']),
      cost: read(business['cost']),
      photos: photos.toSet().toList(),
      weeklyHours: read(business['opentime_week']),
      businessArea: read(business['business_area']).isNotEmpty
          ? read(business['business_area'])
          : read(m['business_area']),
      feature: read(business['tag']).isNotEmpty
          ? read(business['tag'])
          : read(m['tag']),
      parkingType: read(business['parking_type']).isNotEmpty
          ? read(business['parking_type'])
          : read(m['parking_type']),
      floor: read(indoor['floor']),
      alias: read(m['alias']),
      children: childRows
          .whereType<Map>()
          .map(
            (row) => Poi.fromMap({
              ...row.cast<String, dynamic>(),
              'children': const [],
              'cityname': read(m['cityname']),
            }),
          )
          .where(
            (p) => p.name.isNotEmpty && (p.latitude != 0 || p.longitude != 0),
          )
          .toList(),
      distance: meters == null
          ? ''
          : meters >= 1000
          ? '${(meters / 1000).toStringAsFixed(1)}km'
          : '${meters}m',
      latitude: location.length == 2 ? double.tryParse(location[1]) ?? 0 : 0,
      longitude: location.isNotEmpty ? double.tryParse(location[0]) ?? 0 : 0,
    );
  }
  static String read(dynamic value) => value is String
      ? value
      : value is num
      ? '$value'
      : value is List && value.isNotEmpty
      ? read(value.first)
      : '';
}

typedef PlaceGeography = ({
  String? city,
  String? country,
  String? address,
  String? province,
  String? district,
  String? adcode,
});

class PoiSearchService {
  // An omitted type defaults to food/services/residences in AMap, excluding sights.
  static final nearbyTypes = nearbyCategories
      .map((c) => c.code)
      .whereType<String>()
      .where((code) => code.endsWith('0000'))
      .join('|');
  static final Dio _http = Dio(
    BaseOptions(
      baseUrl: 'https://restapi.amap.com',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  static Future<Map<String, dynamic>> _get(
    String path,
    Map<String, dynamic> params,
  ) async {
    final result = await _http.get<Map<String, dynamic>>(
      path,
      queryParameters: {'key': AppConfig.amapWebApiKey, ...params},
    );
    final data = result.data ?? {};
    if (data['status'] != '1') throw StateError('地点服务暂不可用');
    return data;
  }

  static List<Poi> _parse(Map<String, dynamic> data) =>
      (data['pois'] as List? ?? [])
          .whereType<Map>()
          .map((m) => Poi.fromMap(m.cast<String, dynamic>()))
          .where(
            (p) =>
                p.name.isNotEmpty &&
                p.latitude.abs() <= 90 &&
                p.longitude.abs() <= 180 &&
                (p.latitude != 0 || p.longitude != 0),
          )
          .toList();
  static Future<List<Poi>> searchNearby(
    double lat,
    double lng, {
    int limit = 10,
    String? types,
    int radius = 1000,
  }) async => _parse(
    await _get('/v3/place/around', {
      'location': '$lng,$lat',
      'radius': radius,
      'types': types ?? nearbyTypes,
      'sortrule': 'distance',
      'offset': limit,
      'extensions': 'all',
    }),
  );
  static Future<List<Poi>> searchByName(
    String keyword,
    double lat,
    double lng,
  ) async => _parse(
    await _get('/v3/place/text', {
      'keywords': keyword,
      'offset': 20,
      'extensions': 'all',
    }),
  );
  static Future<Poi?> byId(String id, double lat, double lng) async {
    if (id.isEmpty) return null;
    for (final path in ['/v5/place/detail', '/v3/place/detail']) {
      try {
        final values = _parse(
          await _get(path, {
            'id': id,
            'show_fields': 'business,photos,children,indoor',
            'extensions': 'all',
          }),
        );
        if (values.isNotEmpty) return values.first;
      } catch (_) {
        /* v3 fallback for accounts without POI 2.0 detail access. */
      }
    }
    return null;
  }

  static Future<Poi> details(Poi seed) async {
    final direct = await byId(seed.id, seed.latitude, seed.longitude);
    if (direct != null) return direct;
    if (seed.id.isEmpty && seed.name.isNotEmpty) {
      try {
        final candidates = await searchByName(
          seed.name,
          seed.latitude,
          seed.longitude,
        );
        for (final candidate in candidates) {
          if (candidate.name == seed.name &&
              const Distance().as(
                    LengthUnit.Meter,
                    LatLng(seed.latitude, seed.longitude),
                    LatLng(candidate.latitude, candidate.longitude),
                  ) <
                  150) {
            return candidate;
          }
        }
      } catch (_) {}
    }
    return seed;
  }

  static Future<PlaceGeography> reverseGeocode(double lat, double lng) async {
    final data = await _get('/v3/geocode/regeo', {'location': '$lng,$lat'});
    final geo = data['regeocode'] is Map ? data['regeocode'] as Map : const {};
    final c = geo['addressComponent'] is Map
        ? geo['addressComponent'] as Map
        : const {};
    final province = Poi.read(c['province']);
    final city = Poi.read(c['city']);
    return (
      city: city.isNotEmpty ? city : province,
      province: province,
      district: Poi.read(c['district']),
      country: Poi.read(c['country']),
      adcode: Poi.read(c['adcode']),
      address: Poi.read(geo['formatted_address']),
    );
  }

  static Future<({double latitude, double longitude})?> convertGps(
    double lat,
    double lng,
  ) async {
    try {
      final data = await _get('/v3/assistant/coordinate/convert', {
        'locations': '$lng,$lat',
        'coordsys': 'gps',
      });
      final point = Poi.read(data['locations']).split(',');
      if (point.length != 2) return null;
      final x = double.tryParse(point[0]), y = double.tryParse(point[1]);
      return x == null || y == null ? null : (latitude: y, longitude: x);
    } catch (_) {
      return null;
    }
  }
}
