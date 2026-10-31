import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tastemap/data/collection_repository.dart';
import 'package:tastemap/models/collection.dart';
import 'package:tastemap/models/collection_view.dart';
import 'package:tastemap/models/place.dart';
import 'package:tastemap/models/primary_tag.dart';
import 'package:tastemap/state/collection_provider.dart';
import 'package:tastemap/widgets/collection_list_sheet.dart';
import 'package:tastemap/widgets/detail_sheet.dart';

class ListRepository extends CollectionRepository {
  final int count;
  ListRepository(this.count);
  @override
  Future<List<CollectionView>> getCollectionViews() async => List.generate(
    count,
    (i) => CollectionView(
      place: Place(
        id: '$i',
        name: '地点$i',
        city: '上海市',
        latitude: 31,
        longitude: 121,
        createdAt: '',
      ),
      collection: Collection(
        id: '$i',
        placeId: '$i',
        primaryTag: PrimaryTag.other,
        note: i == 1 ? 'Coffee Note' : '',
        secondaryTags: i == 1 ? ['周末'] : [],
        createdAt: '',
        updatedAt: '',
      ),
    ),
  );
  @override
  Future<String?> getSetting(String key) async => null;
}

void main() {
  testWidgets('收藏面板保留城市折叠，点击返回地点而不打开详情', (tester) async {
    final provider = CollectionProvider(repository: ListRepository(2));
    await provider.load();
    CollectionView? selected;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showCollectionList(context);
                },
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('我的收藏'), findsOneWidget);
    await tester.tap(find.text('上海市'));
    await tester.pumpAndSettle();
    expect(find.text('地点0'), findsNothing);
    await tester.tap(find.text('上海市'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('地点0'));
    await tester.pumpAndSettle();
    expect(selected?.id, '0');
    expect(find.byType(DetailSheet), findsNothing);
    expect(find.text('我的收藏'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
  testWidgets('搜索支持多字段和大小写，搜索结果不被折叠隐藏且可清空', (tester) async {
    final provider = CollectionProvider(repository: ListRepository(2));
    await provider.load();
    CollectionView? selected;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showCollectionList(context);
                },
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('上海市'));
    await tester.pumpAndSettle();
    expect(find.text('地点1'), findsNothing);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DraggableScrollableSheet>(
            find.byType(DraggableScrollableSheet),
          )
          .controller!
          .size,
      closeTo(.92, .01),
    );
    await tester.enterText(find.byType(TextField), 'COFFEE 周末');
    await tester.pumpAndSettle();
    expect(find.text('地点1'), findsOneWidget);
    expect(find.text('地点0'), findsNothing);
    await tester.enterText(find.byType(TextField), '没有这个地方');
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的收藏'), findsOneWidget);
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), '上海 未分类');
    await tester.pumpAndSettle();
    expect(find.text('地点0'), findsOneWidget);
    expect(find.text('地点1'), findsOneWidget);
    await tester.ensureVisible(find.text('地点1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('地点1'));
    await tester.pumpAndSettle();
    expect(selected?.id, '1');
    expect(find.byType(DetailSheet), findsNothing);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
  testWidgets('大量收藏按需构建，面板下拉可关闭', (tester) async {
    final provider = CollectionProvider(repository: ListRepository(1000));
    await provider.load();
    var closed = false;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  await showCollectionList(context);
                  closed = true;
                },
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile).evaluate().length, lessThan(40));
    await tester.drag(find.text('我的收藏'), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
}
