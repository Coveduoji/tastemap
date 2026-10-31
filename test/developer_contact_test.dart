import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tastemap/screens/developer_contact_screen.dart';

void main() {
  testWidgets('提供已确认的邮箱与GitHub，复制邮箱不附带用户数据', (tester) async {
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(const MaterialApp(home: DeveloperContactScreen()));
    await tester.pumpAndSettle();
    expect(find.text('miston.wei@qq.com'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('微信'), findsNothing);
    await tester.tap(find.byTooltip('复制邮箱'));
    await tester.pumpAndSettle();
    expect(copied, 'miston.wei@qq.com');
    expect(find.text('邮箱已复制'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
