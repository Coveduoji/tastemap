import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tastemap/screens/app_icon_screen.dart';

void main() {
  const channel = MethodChannel('flutter_dynamic_icon_plus');
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets('读取系统当前图标，切换并从系统重新确认选中状态', (tester) async {
    var current = 'com.tastemap.tastemap.IconWander';
    final selections = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'supportsAlternateIcons':
              return true;
            case 'getAlternateIconName':
              return current;
            case 'setAlternateIconName':
              final name = (call.arguments as Map)['iconName'] as String;
              selections.add(name);
              current = 'com.tastemap.tastemap.$name';
              return true;
          }
          return null;
        });
    await tester.pumpWidget(const MaterialApp(home: AppIconScreen()));
    await tester.pumpAndSettle();
    expect(find.text('漫游'), findsOneWidget);
    expect(find.text('手账'), findsOneWidget);
    await tester.tap(find.text('手账'));
    await tester.pumpAndSettle();
    expect(selections, ['IconJournal']);
    expect(find.text('已切换，返回桌面查看'), findsOneWidget);
    await tester.tap(find.text('手账'));
    await tester.pumpAndSettle();
    expect(selections, ['IconJournal']);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(const MaterialApp(home: AppIconScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('漫游'));
    await tester.pumpAndSettle();
    expect(selections, ['IconJournal', 'IconWander']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换失败不标记成功，允许重试', (tester) async {
    var fail = true;
    var current = 'com.tastemap.tastemap.IconWander';
    var attempts = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'supportsAlternateIcons') return true;
          if (call.method == 'getAlternateIconName') return current;
          if (call.method == 'setAlternateIconName') {
            attempts++;
            if (fail) throw PlatformException(code: 'unavailable');
            current = 'com.tastemap.tastemap.IconJournal';
            return true;
          }
          return null;
        });
    await tester.pumpWidget(const MaterialApp(home: AppIconScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('手账'));
    await tester.pumpAndSettle();
    expect(find.text('切换失败，请重试'), findsOneWidget);
    expect(current, endsWith('IconWander'));
    fail = false;
    await tester.tap(find.text('手账'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(current, endsWith('IconJournal'));
    expect(tester.takeException(), isNull);
  });
}
