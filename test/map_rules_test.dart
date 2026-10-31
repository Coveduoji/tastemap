import 'package:flutter_test/flutter_test.dart';
import 'package:tastemap/models/poi_category.dart';
import 'package:tastemap/models/primary_tag.dart';
import 'package:tastemap/utils/administrative_clusters.dart';

void main() {
  test('住宅、办公、医院使用高德分类，未知地点不再默认为餐饮', () {
    expect(
      PoiCategory.fromAmap('120302', '商务住宅;住宅区;住宅小区'),
      PoiCategory.residence,
    );
    expect(PoiCategory.fromAmap('120302', '餐饮'), PoiCategory.residence);
    expect(PoiCategory.fromAmap('170100', '公司'), PoiCategory.office);
    expect(PoiCategory.fromAmap('090100', '医院'), PoiCategory.health);
    expect(PoiCategory.fromAmap('', '住宅小区'), PoiCategory.residence);
    expect(PoiCategory.fromAmap('', ''), PoiCategory.other);
    expect(PoiCategory.residence.suggestedTag, PrimaryTag.other);
    expect(PoiCategory.fromAmap('050000', '餐饮'), PoiCategory.food);
  });
  test('行政层级在5、8、11、14级切换，14级起只显示收藏点', () {
    expect(AdministrativeClusters.level(4.9), RegionLevel.country);
    expect(AdministrativeClusters.level(5), RegionLevel.province);
    expect(AdministrativeClusters.level(8), RegionLevel.city);
    expect(AdministrativeClusters.level(11), RegionLevel.district);
    expect(AdministrativeClusters.level(14), RegionLevel.place);
  });
}
