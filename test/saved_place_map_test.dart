import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tastemap/data/collection_repository.dart';
import 'package:tastemap/models/collection.dart';
import 'package:tastemap/models/collection_view.dart';
import 'package:tastemap/models/place.dart';
import 'package:tastemap/models/primary_tag.dart';
import 'package:tastemap/screens/map_screen.dart';
import 'package:tastemap/state/collection_provider.dart';
import 'package:tastemap/widgets/detail_sheet.dart';

class _SavedPlaceRepository extends CollectionRepository {
  @override
  Future<String?> getSetting(String key) async => null;
  @override
  Future<bool> setSetting(String key, String value) async => true;
  @override
  Future<List<CollectionView>> getCollectionViews() async => [
    CollectionView(
      place: Place(
        id: 'saved',
        name: '测试收藏地点',
        latitude: 31.2,
        longitude: 121.5,
        city: '上海市',
        province: '上海市',
        district: '浦东新区',
        createdAt: '2026-11-01',
      ),
      collection: Collection(
        id: 'saved',
        placeId: 'saved',
        primaryTag: PrimaryTag.other,
        createdAt: '2026-11-01',
        updatedAt: '2026-11-01',
      ),
    ),
  ];
}

void main() {
  testWidgets('点击收藏展示明亮的地图和收藏信息，拖动调整地图，关闭恢复地图', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = CollectionProvider(repository: _SavedPlaceRepository());
    await provider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final fullHeight = tester.getSize(find.byType(FlutterMap)).height;
    await tester.tap(find.text('我的收藏'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试收藏地点').last);
    await tester.pumpAndSettle();
    expect(find.byType(DetailSheet), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('导航'), findsOneWidget);
    expect(
      tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .where((barrier) => (barrier.color?.a ?? 0) > 0),
      isEmpty,
    );
    final map = tester.getRect(find.byType(FlutterMap));
    final sheet = tester.getRect(find.byType(DetailSheet));
    expect(map.height, closeTo(fullHeight * .52, 1));
    expect(map.bottom, closeTo(sheet.top, 1));
    final camera = MapController.of(
      tester.element(find.byType(TileLayer)),
    ).camera;
    expect(camera.center.latitude, closeTo(31.2, .001));
    expect(camera.center.longitude, closeTo(121.5, .001));
    await tester.dragFrom(Offset(210, sheet.top + 25), const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(FlutterMap)).height,
      lessThan(map.height),
    );
    final top = tester.getRect(find.byType(DetailSheet)).top;
    await tester.dragFrom(Offset(210, top + 25), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.byType(DetailSheet), findsNothing);
    expect(tester.getSize(find.byType(FlutterMap)).height, fullHeight);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
}
