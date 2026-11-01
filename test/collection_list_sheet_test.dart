import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
  final deleted = <String>[];
  bool deleteSucceeds = true;
  @override
  Future<bool> delete(String collectionId) async {
    if (!deleteSucceeds) return false;
    deleted.add(collectionId);
    return true;
  }

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
  ).where((view) => !deleted.contains(view.id)).toList();
  @override
  Future<String?> getSetting(String key) async => null;
}

Future<CollectionProvider> openSwipeList(
  WidgetTester tester,
  ListRepository repo,
) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final provider = CollectionProvider(repository: repo);
  await provider.load();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showCollectionList(context),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
  return provider;
}

Future<void> revealDelete(WidgetTester tester, String name) async {
  final row = find.ancestor(
    of: find.text(name),
    matching: find.byType(Slidable),
  );
  await tester.drag(row, const Offset(-260, 0));
  await tester.pumpAndSettle();
}

Future<void> confirmDelete(WidgetTester tester) async {
  await tester.tap(find.text('删除').hitTestable());
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text('删除')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('左滑露出右侧删除按钮，取消不删除，确认后仅删除该条并保留列表', (tester) async {
    final repo = ListRepository(2);
    await openSwipeList(tester, repo);
    expect(find.text('删除').hitTestable(), findsNothing);
    await revealDelete(tester, '地点0');
    expect(find.text('删除').hitTestable(), findsOneWidget);
    expect(repo.deleted, isEmpty);
    await revealDelete(tester, '地点1');
    expect(find.text('删除').hitTestable(), findsOneWidget);
    await tester.tap(find.text('删除').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('确认删除「地点1」？此操作不可恢复。'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repo.deleted, isEmpty);
    await revealDelete(tester, '地点0');
    await confirmDelete(tester);
    expect(repo.deleted, ['0']);
    expect(find.text('地点0'), findsNothing);
    expect(find.text('地点1'), findsOneWidget);
    expect(find.text('1 个'), findsOneWidget);
    expect(find.text('我的收藏'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索结果可左滑删除，保留搜索词并更新空态', (tester) async {
    final repo = ListRepository(3);
    await openSwipeList(tester, repo);
    await tester.enterText(find.byType(TextField), '地点1');
    await tester.pumpAndSettle();
    await revealDelete(tester, '地点1');
    await confirmDelete(tester);
    expect(repo.deleted, ['1']);
    expect(find.text('没有匹配的收藏'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '地点1',
    );
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    expect(find.text('地点0'), findsOneWidget);
    expect(find.text('地点1'), findsNothing);
    expect(find.text('地点2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('删除失败保留原记录并允许重试', (tester) async {
    final repo = ListRepository(1)..deleteSucceeds = false;
    await openSwipeList(tester, repo);
    await revealDelete(tester, '地点0');
    await confirmDelete(tester);
    expect(find.text('删除失败，请重试'), findsOneWidget);
    expect(find.text('地点0'), findsOneWidget);
    expect(repo.deleted, isEmpty);
    repo.deleteSucceeds = true;
    await revealDelete(tester, '地点0');
    await confirmDelete(tester);
    expect(repo.deleted, ['0']);
    expect(find.text('还没有收藏'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
