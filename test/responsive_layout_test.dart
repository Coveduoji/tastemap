import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tastemap/screens/app_icon_screen.dart';
import 'package:tastemap/screens/developer_contact_screen.dart';
import 'package:tastemap/screens/map_screen.dart';
import 'package:tastemap/screens/profile_screen.dart';
import 'package:tastemap/screens/settings_screen.dart';
import 'package:tastemap/state/collection_provider.dart';

void main() {
  const channel = MethodChannel('flutter_dynamic_icon_plus');
  final cases = [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(360, 800), scale: 1.0),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(412, 915), scale: 1.0),
    (size: const Size(800, 1280), scale: 1.0),
    (size: const Size(844, 390), scale: 1.0),
    (size: const Size(320, 720), scale: 1.5),
  ];
  for (final entry in cases) {
    testWidgets('主要页面适配 ${entry.size} 字体 ${entry.scale}', (tester) async {
      tester.view.physicalSize = entry.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return call.method == 'supportsAlternateIcons'
                ? true
                : 'com.tastemap.tastemap.IconWander';
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final provider = CollectionProvider();
      Future<void> show(Widget page) async {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(entry.scale),
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                ),
                child: child!,
              ),
              home: page,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${page.runtimeType} ${entry.size}',
        );
      }

      await show(const MapScreen());
      final add = tester.getRect(find.byTooltip('添加地点'));
      final favorites = tester.getRect(find.widgetWithText(TextButton, '我的收藏'));
      final north = tester.getRect(find.byTooltip('朝北'));
      expect(favorites.right, lessThanOrEqualTo(add.left));
      expect(north.left, greaterThanOrEqualTo(add.right));
      expect(add.center.dx, closeTo(entry.size.width / 2, .1));
      await show(const ProfileScreen());
      await show(const SettingsScreen());
      await tester.scrollUntilVisible(find.text('联系开发者'), 150);
      expect(find.text('联系开发者'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await show(const AppIconScreen());
      expect(find.text('漫游'), findsOneWidget);
      expect(find.text('手账'), findsOneWidget);
      await show(const DeveloperContactScreen());
      expect(find.text(DeveloperContactScreen.email), findsOneWidget);
      expect(find.text('微信'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      provider.dispose();
      expect(tester.takeException(), isNull);
    });
  }
}
