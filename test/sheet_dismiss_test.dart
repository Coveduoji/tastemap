import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('标准面板支持从内容下拉关闭，无关闭按钮', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: .6,
                  minChildSize: .25,
                  maxChildSize: .92,
                  expand: false,
                  shouldCloseOnMinExtent: true,
                  builder: (_, scroll) => ListView(
                    controller: scroll,
                    children: const [
                      SizedBox(height: 160, child: Center(child: Text('附近地点'))),
                    ],
                  ),
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.drag(find.text('附近地点'), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('附近地点'), findsNothing);
  });
}
