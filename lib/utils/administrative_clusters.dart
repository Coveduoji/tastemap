import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';
import '../models/collection_view.dart';

enum RegionLevel { country, province, city, district, place }

class PlaceCluster {
  final String id;
  final String title;
  final RegionLevel level;
  final List<CollectionView> members;
  const PlaceCluster(this.id, this.title, this.level, this.members);
  bool get isPlace => level == RegionLevel.place;
  LatLng get point => LatLng(
    members.map((v) => v.latitude).average,
    members.map((v) => v.longitude).average,
  );
  double get nextZoom => switch (level) {
    RegionLevel.country => 5.5,
    RegionLevel.province => 8.5,
    RegionLevel.city => 11.5,
    RegionLevel.district => 14.5,
    RegionLevel.place => 16,
  };
}

/// Business grouping uses administrative identities, never screen distance.
class AdministrativeClusters {
  static RegionLevel level(double zoom) => zoom < 5
      ? RegionLevel.country
      : zoom < 8
      ? RegionLevel.province
      : zoom < 11
      ? RegionLevel.city
      : zoom < 14
      ? RegionLevel.district
      : RegionLevel.place;
  static List<PlaceCluster> build(List<CollectionView> views, double zoom) {
    final current = level(zoom);
    if (current == RegionLevel.place) {
      return views
          .map((v) => PlaceCluster(v.id, v.name, current, [v]))
          .toList();
    }
    List<String?> path(CollectionView v) => [
      v.country,
      v.place.province,
      v.city,
      v.place.district,
    ];
    final groups = groupBy(views, (v) {
      final fields = path(v).take(current.index + 1).toList();
      // Missing geography is kept separate until geocoding completes.
      if (fields.last?.isNotEmpty != true) return 'unknown:${v.placeId}';
      return fields.map((s) => s ?? '').join('|');
    });
    return groups.entries.map((e) {
      final title = path(e.value.first)[current.index];
      return PlaceCluster(
        'region:${current.name}:${e.key}',
        title?.isNotEmpty == true ? title! : e.value.first.name,
        current,
        e.value,
      );
    }).toList();
  }
}
