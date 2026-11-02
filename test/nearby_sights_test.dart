import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tastemap/data/poi_search.dart';
import 'package:tastemap/models/poi_category.dart';
import 'package:tastemap/widgets/poi_sheet.dart';

const sight = Poi(
  name: '城市公园',
  addr: '公开测试地点',
  typeCode: '110101',
  distance: '1500',
  latitude: 39.916,
  longitude: 116.397,
);
const cafe = Poi(
  name: '街角咖啡',
  addr: '公开测试地点',
  typeCode: '050500',
  distance: '30',
  latitude: 39.916,
  longitude: 116.397,
);

Future<void> mountSheet(WidgetTester tester, NearbyPoiSearch search) async {
  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PoiSheet(
          center: const LatLng(39.916, 116.397),
          scrollController: scroll,
          nearbySearch: search,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('全部分类可以选择酒吧，编码与真实地图分类一致', (tester) async {
    String? requested;
    await mountSheet(tester, (
      lat,
      lng, {
      limit = 10,
      types,
      radius = 1000,
    }) async {
      requested = types;
      return [];
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('全部分类'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '酒吧').hitTestable().last);
    await tester.pumpAndSettle();
    expect(requested, '080304');
    expect(PoiCategory.fromAmap(requested!, ''), PoiCategory.bar);
    expect(PoiCategory.fromAmap('050400', ''), PoiCategory.food);
    expect(PoiCategory.fromAmap('050500', ''), PoiCategory.coffee);
  });

  testWidgets('附近支持景点筛选，查询三公里并可恢复全部地点', (tester) async {
    final calls = <String?>[];
    await mountSheet(tester, (
      lat,
      lng, {
      limit = 10,
      types,
      radius = 1000,
    }) async {
      expect((lat, lng), (39.916, 116.397));
      expect(radius, 3000);
      expect(limit, 25);
      calls.add(types);
      return types == '110000' ? [sight] : [cafe, sight];
    });
    await tester.pumpAndSettle();
    expect(find.text('城市公园'), findsOneWidget);
    expect(find.text('街角咖啡'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '景点'));
    await tester.pumpAndSettle();
    expect(find.text('城市公园'), findsOneWidget);
    expect(find.text('街角咖啡'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
    await tester.pumpAndSettle();
    expect(find.text('街角咖啡'), findsOneWidget);
    expect(calls, [null, '110000', null]);
  });

  testWidgets('切换景点后，迟到的全部地点结果不会覆盖当前筛选', (tester) async {
    final first = Completer<List<Poi>>();
    final filtered = Completer<List<Poi>>();
    await mountSheet(tester, (lat, lng, {limit = 10, types, radius = 1000}) {
      return types == null ? first.future : filtered.future;
    });
    await tester.tap(find.widgetWithText(ChoiceChip, '景点'));
    await tester.pump();
    filtered.complete([sight]);
    await tester.pumpAndSettle();
    first.complete([cafe]);
    await tester.pumpAndSettle();
    expect(find.text('城市公园'), findsOneWidget);
    expect(find.text('街角咖啡'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('景点查询失败可重试，空结果仍可手动添加地点', (tester) async {
    var filteredCalls = 0;
    await mountSheet(tester, (
      lat,
      lng, {
      limit = 10,
      types,
      radius = 1000,
    }) async {
      if (types == null) return [cafe];
      if (++filteredCalls == 1) throw StateError('network unavailable');
      return [];
    });
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '景点'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(filteredCalls, 2);
    expect(find.text('附近暂无地点'), findsOneWidget);
    expect(find.text('添加地点'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
