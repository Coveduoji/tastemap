import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tastemap/screens/profile_screen.dart';
import 'package:tastemap/state/collection_provider.dart';

void main() {
  testWidgets('足迹页在窄屏与放大字体下展示真实空态且没有布局溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CollectionProvider(),
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('我的足迹'), findsOneWidget);
    expect(find.text('收藏一处喜欢的地方。'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    expect(find.text('下一座城市，等你点亮'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
