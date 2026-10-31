import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:tastemap/screens/map_screen.dart';
import 'package:tastemap/state/collection_provider.dart';
import 'package:tastemap/widgets/poi_sheet.dart';

void main() {
  testWidgets('地图铺满屏幕，固定中心标点可点击且不依赖已就绪camera', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CollectionProvider(),
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FlutterMap)),
      tester.getSize(find.byType(Scaffold).first),
    );
    expect(find.byTooltip('放大'), findsNothing);
    expect(find.byTooltip('缩小'), findsNothing);
    expect(find.text('品味地图'), findsNothing);
    expect(
      tester.getSize(find.widgetWithText(TextButton, '我的收藏')).width,
      lessThan(200),
    );
    final favorites = tester.getRect(find.widgetWithText(TextButton, '我的收藏'));
    final add = tester.getRect(find.byTooltip('添加地点'));
    final north = tester.getRect(find.byTooltip('朝北'));
    final locating = find.byTooltip('定位').evaluate().isNotEmpty
        ? find.byTooltip('定位')
        : find.byTooltip('定位中');
    final locate = tester.getRect(locating);
    expect(add.center.dx, closeTo(180, .1));
    expect(north.center.dy, closeTo(favorites.center.dy, .1));
    expect(locate.center.dy, closeTo(favorites.center.dy, .1));
    expect(north.left, greaterThan(add.right));
    expect(locate.left, greaterThan(north.left));
    expect(favorites.right, lessThan(add.left));
    final pin = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == '收藏地图中心位置',
    );
    expect(pin, findsOneWidget);
    expect(
      find.descendant(of: pin, matching: find.byType(GestureDetector)),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
  testWidgets('收藏成功提示位于顶部，底部按钮可用，短暂显示后自动消失', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CollectionProvider(),
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byTooltip('添加地点'));
    await tester.pumpAndSettle();
    tester.widget<PoiSheet>(find.byType(PoiSheet)).onSaved!();
    await tester.pumpAndSettle();
    final notice = find.text('已收藏');
    expect(notice, findsOneWidget);
    expect(tester.getRect(notice).bottom, lessThan(100));
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byTooltip('添加地点').hitTestable(), findsOneWidget);
    expect(find.text('我的收藏').hitTestable(), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(notice, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
