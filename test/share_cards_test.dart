import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tastemap/widgets/share_memory_card.dart';
import 'package:tastemap/widgets/share_card_sheet.dart';
import 'package:tastemap/widgets/detail_sheet.dart';
import 'photo_viewer_test.dart' show UnavailableImage;
import 'import_service_test.dart' show sample;
import 'package:tastemap/models/collection_view.dart';

void main() {
  testWidgets('底部四键均有图标文字、地址对齐，窄屏大字体可打开分享', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(body: DetailSheet(view: sample('a'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nav = find.widgetWithText(FilledButton, '导航');
    final share = find.widgetWithText(FilledButton, '分享');
    final delete = find.byIcon(Icons.delete_outline);
    await tester.ensureVisible(share);
    await tester.pumpAndSettle();
    expect(tester.getCenter(nav).dx, lessThan(tester.getCenter(share).dx));
    expect(tester.getCenter(share).dx, lessThan(tester.getCenter(delete).dx));
    for (final entry in const {
      '编辑': Icons.edit,
      '导航': Icons.navigation,
      '分享': Icons.ios_share,
      '删除': Icons.delete_outline,
    }.entries) {
      final button = find.widgetWithText(FilledButton, entry.key);
      expect(
        find.descendant(of: button, matching: find.byIcon(entry.value)),
        findsOneWidget,
      );
      expect(
        tester.getSize(button).width,
        closeTo(tester.getSize(share).width, .1),
      );
      expect(
        tester.getSize(button).height,
        closeTo(tester.getSize(share).height, .1),
      );
    }
    expect(
      (tester.getCenter(find.byIcon(Icons.location_on)).dy -
              tester.getCenter(find.text('北京')).dy)
          .abs(),
      lessThan(.5),
    );
    expect(find.byTooltip('分享回忆'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(find.byType(ShareCardSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('所有模板无照片均显示默认封面，加载失败也回退到封面', (tester) async {
    for (final style in MemoryCardStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 400,
                child: ShareMemoryCard(view: sample('a'), style: style),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('默认旅行封面'),
        findsOneWidget,
        reason: style.label,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareMemoryCard(
            view: sample('a'),
            style: MemoryCardStyle.minimal,
            photos: [UnavailableImage()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('默认旅行封面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('真实文件照片可切换封面，导出组件使用所选照片', (tester) async {
    final temp = Directory.systemTemp.createTempSync('shitu-cover-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final a = File(
      'assets/app_icons/wander.png',
    ).copySync('${temp.path}/a.png');
    final b = File(
      'assets/app_icons/journal.png',
    ).copySync('${temp.path}/b.png');
    final original = sample('cover');
    final view = CollectionView(
      place: original.place,
      collection: original.collection.copyWith(images: [a.path, b.path]),
    );
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: (context) => const SizedBox())),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(SizedBox).first);
      for (final file in [a, b]) {
        await precacheImage(FileImage(file), context);
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ShareCardSheet(view: view)),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '照片 2'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    final card = tester.widget<ShareMemoryCard>(find.byType(ShareMemoryCard));
    expect((card.photos.first as FileImage).file.path, b.path);
    expect(card.photos.length, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('六款模板长文本、无照片和大字体均无溢出，隐藏备注和地区', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final style in MemoryCardStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  height: 374,
                  child: ShareMemoryCard(
                    view: sample('a', note: '旅行记忆' * 100),
                    style: style,
                    showNote: false,
                    showCity: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('旅行记忆'), findsNothing);
      expect(find.textContaining('海淀'), findsNothing);
      expect(tester.takeException(), isNull, reason: style.label);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 374,
                child: ShareMemoryCard(
                  view: sample('a', note: '旅行记忆' * 100),
                  style: style,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: style.label);
    }
  });
  testWidgets('分享面板可选择模板并隐藏备注，不会写入收藏', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ShareCardSheet(view: sample('a'))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '夜色'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ShareMemoryCard>(find.byType(ShareMemoryCard)).style,
      MemoryCardStyle.dark,
    );
    await tester.tap(find.widgetWithText(FilterChip, '备注'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ShareMemoryCard>(find.byType(ShareMemoryCard)).showNote,
      isFalse,
    );
    expect(find.text('保存图片'), findsOneWidget);
    expect(find.text('分享'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
