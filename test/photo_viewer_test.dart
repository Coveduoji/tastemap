import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:tastemap/widgets/photo_viewer.dart';

class UnavailableImage extends ImageProvider<UnavailableImage> {
  @override
  Future<UnavailableImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    UnavailableImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Future.error(StateError('unavailable')));
}

Future<void> openViewer(
  WidgetTester tester,
  List<ImageProvider> images, {
  int initialIndex = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const TextField(decoration: InputDecoration(hintText: '备注')),
              TextButton(
                onPressed: () => showPhotoViewer(
                  context,
                  images: images,
                  initialIndex: initialIndex,
                ),
                child: const Text('查看照片'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(TextField));
    for (final image in images.whereType<MemoryImage>()) {
      await precacheImage(image, context);
    }
  });
  await tester.enterText(find.byType(TextField), '旅行中留下的一句话');
  await tester.tap(find.text('查看照片'));
  await tester.pumpAndSettle();
}

void main() {
  late List<ImageProvider> images;
  setUp(() {
    images = [
      MemoryImage(File('assets/app_icons/wander.png').readAsBytesSync()),
      MemoryImage(File('assets/app_icons/journal.png').readAsBytesSync()),
    ];
  });

  testWidgets('从点击的照片打开，可左右切换，关闭保留未保存的备注', (tester) async {
    await openViewer(tester, images, initialIndex: 1);
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.drag(find.byType(PhotoViewGallery), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewGallery), findsNothing);
    expect(find.text('旅行中留下的一句话'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('双击放大照片，系统返回关闭预览', (tester) async {
    await openViewer(tester, images.take(1).toList());
    final photo = find.byType(RawImage).first;
    List<String> transforms() => tester
        .widgetList<Transform>(
          find.ancestor(of: photo, matching: find.byType(Transform)),
        )
        .map((widget) => widget.transform.toString())
        .toList();
    final before = transforms();
    final center = tester.getCenter(photo);
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(transforms(), isNot(equals(before)));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewGallery), findsNothing);
    expect(find.text('旅行中留下的一句话'), findsOneWidget);
  });

  testWidgets('照片加载失败仍可切换到下一张和关闭', (tester) async {
    await openViewer(tester, [UnavailableImage(), images.first]);
    expect(find.text('照片无法加载'), findsOneWidget);
    await tester.drag(find.byType(PhotoViewGallery), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('照片无法加载'), findsNothing);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
