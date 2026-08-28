/// 地点基础信息（PRD §7.1 Place 表）。
/// 与收藏记录（Collection）解耦：同一地点未来可被复用/去重。
class Place {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String type; // 'custom' | 'poi'
  final String? source;
  final String? foursquareId;
  final String createdAt;

  const Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.type = 'custom',
    this.source,
    this.foursquareId,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'country': country,
        'type': type,
        'source': source,
        'foursquare_id': foursquareId,
        'created_at': createdAt,
      };

  factory Place.fromMap(Map<String, Object?> map) => Place(
        id: map['id'] as String,
        name: map['name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        city: map['city'] as String?,
        country: map['country'] as String?,
        type: (map['type'] as String?) ?? 'custom',
        source: map['source'] as String?,
        foursquareId: map['foursquare_id'] as String?,
        createdAt: (map['created_at'] as String?) ?? '',
      );
}
