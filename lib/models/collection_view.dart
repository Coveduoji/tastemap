import 'collection.dart';
import 'place.dart';
import 'primary_tag.dart';

/// 收藏 + 地点的合并视图，供地图 / 详情 / Profile 读取。
/// 由 Repository 通过 JOIN 查询组装，UI 层只依赖这一层。
class CollectionView {
  final Collection collection;
  final Place place;

  const CollectionView({required this.collection, required this.place});

  String get id => collection.id;
  String get placeId => place.id;
  String get name => place.name;
  double get latitude => place.latitude;
  double get longitude => place.longitude;
  String? get city => place.city;
  String? get country => place.country;
  PrimaryTag get tag => collection.primaryTag;
  bool get visited => collection.visited;
  String get note => collection.note;
  List<String> get secondaryTags => collection.secondaryTags;
  List<String> get images => collection.images;
  String get visitedStatus => collection.visitedStatus;
  String get createdAt => collection.createdAt;

  /// 由 JOIN 查询的扁平行组装（列名见 collection_repository.dart）。
  factory CollectionView.fromRow(Map<String, Object?> row) {
    final collection = Collection.fromMap({
      'id': row['id'],
      'place_id': row['place_id'],
      'primary_tag': row['primary_tag'],
      'secondary_tags': row['secondary_tags'],
      'note': row['note'],
      'images': row['images'],
      'visited_status': row['visited_status'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
    final place = Place.fromMap({
      'id': row['place_id'],
      'name': row['name'],
      'latitude': row['latitude'],
      'longitude': row['longitude'],
      'city': row['city'],
      'country': row['country'],
      'province': row['province'],
      'district': row['district'],
      'adcode': row['adcode'],
      'amap_id': row['amap_id'],
      'address': row['address'],

      'type': row['type'],
      'source': row['source'],
      'foursquare_id': row['foursquare_id'],
      'created_at': row['created_at'],
    });
    return CollectionView(collection: collection, place: place);
  }
}
