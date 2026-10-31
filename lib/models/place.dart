/// 地点基础信息（PRD §7.1 Place 表）。
/// 与收藏记录（Collection）解耦：同一地点未来可被复用/去重。
class Place {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? province;
  final String? district;
  final String? adcode;
  final String? amapId;
  final String? address;

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
    this.province,
    this.district,
    this.adcode,
    this.amapId,
    this.address,

    this.type = 'custom',
    this.source,
    this.foursquareId,
    required this.createdAt,
  });

  Place copyWith({
    String? province,
    String? city,
    String? district,
    String? country,
    String? adcode,
    String? amapId,
    String? address,
  }) => Place(
    id: id,
    name: name,
    latitude: latitude,
    longitude: longitude,
    province: province ?? this.province,
    city: city ?? this.city,
    district: district ?? this.district,
    country: country ?? this.country,
    adcode: adcode ?? this.adcode,
    amapId: amapId ?? this.amapId,
    address: address ?? this.address,
    type: type,
    source: source,
    foursquareId: foursquareId,
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'country': country,
    'province': province,
    'district': district,
    'adcode': adcode,
    'amap_id': amapId,
    'address': address,

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
    province: map['province'] as String?,
    district: map['district'] as String?,
    adcode: map['adcode'] as String?,
    amapId: map['amap_id'] as String?,
    address: map['address'] as String?,

    type: (map['type'] as String?) ?? 'custom',
    source: map['source'] as String?,
    foursquareId: map['foursquare_id'] as String?,
    createdAt: (map['created_at'] as String?) ?? '',
  );
}
