import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:tastemap/screens/map_screen.dart';
import 'package:tastemap/state/collection_provider.dart';

void main() {
  testWidgets('地图铺满屏幕，固定中心标点可点击且不依赖已就绪camera', (tester) async {
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
}
