import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tastemap/data/export_service.dart';
import 'package:tastemap/models/collection.dart';
import 'package:tastemap/models/collection_view.dart';
import 'package:tastemap/models/place.dart';
import 'package:tastemap/models/primary_tag.dart';
import 'package:tastemap/utils/administrative_clusters.dart';
import 'custom_tag_deletion_test.dart' show DeletionRepository;
import 'package:tastemap/state/collection_provider.dart';

CollectionView view(String id, String province, String city, String district) =>
    CollectionView(
      place: Place(
        id: id,
        name: '=地点,"测试"',
        latitude: 31,
        longitude: 121,
        country: '中国',
        province: province,
        city: city,
        district: district,
        createdAt: '',
      ),
      collection: Collection(
        id: id,
        placeId: id,
        primaryTag: PrimaryTag.food,
        note: '多行\n备注',
        createdAt: '',
        updatedAt: '',
      ),
    );
void main() {
  test('行政区聚合层级互斥，不混合跨省同名区', () {
    final places = [
      view('1', '甲省', '甲市', '同名区'),
      view('2', '甲省', '甲市', '同名区'),
      view('3', '乙省', '乙市', '同名区'),
    ];
    expect(AdministrativeClusters.build(places, 4).single.members.length, 3);
    for (final zoom in [5.0, 8.0, 11.0]) {
      final groups = AdministrativeClusters.build(places, zoom);
      expect(groups.length, 2);
      expect(groups.every((g) => !g.isPlace), isTrue);
      expect(
        groups.expand((g) => g.members).map((v) => v.id).toSet().length,
        3,
      );
    }
    expect(
      AdministrativeClusters.build(
        places,
        14,
      ).every((g) => g.isPlace && g.members.length == 1),
      isTrue,
    );
  });
  test('导出CSV转义换行引号，JSON保留行政区及收藏内容', () {
    final places = [view('1', '甲省', '甲市', '甲区')];
    final csv = ExportService.encode(places, csv: true);
    final rows = const CsvToListConverter().convert(
      utf8.decode(csv.bytes.sublist(3)),
    );
    expect(rows[1][0], '\'=地点,"测试"');
    expect(rows[1][11], '多行\n备注');
    final json = jsonDecode(
      utf8.decode(ExportService.encode(places, csv: false).bytes),
    );
    expect(json['places'][0]['province'], '甲省');
    expect(json['collections'][0]['note'], '多行\n备注');
  });
  test('首次提示只领取一次，设置在provider重建后恢复', () async {
    final repo = DeletionRepository();
    final p = CollectionProvider(repository: repo);
    expect(await p.claimFirstMapTip(), isTrue);
    expect(await p.claimFirstMapTip(), isFalse);
    await p.setPreference('nearby_reminders', '1');
    final restored = CollectionProvider(repository: repo);
    await restored.load();
    expect(await restored.claimFirstMapTip(), isFalse);
    expect(restored.nearbyReminders, isTrue);
    p.dispose();
    restored.dispose();
  });
}
