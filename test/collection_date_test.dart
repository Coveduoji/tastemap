import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tastemap/data/collection_repository.dart';
import 'package:tastemap/models/collection.dart';
import 'package:tastemap/models/collection_view.dart';
import 'package:tastemap/state/collection_provider.dart';
import 'package:tastemap/widgets/detail_sheet.dart';
import 'import_service_test.dart' show sample;

class _DateRepository extends CollectionRepository {
  CollectionView value = sample('date');
  bool fail = false;
  int writes = 0;
  @override
  Future<String?> getSetting(String key) async => null;
  @override
  Future<List<CollectionView>> getCollectionViews() async => [value];
  @override
  Future<bool> update(Collection collection) async {
    writes++;
    if (fail) return false;
    value = CollectionView(place: value.place, collection: collection);
    return true;
  }
}

void main() {
  Future<_DateRepository> show(WidgetTester tester) async {
    final repo = _DateRepository();
    final provider = CollectionProvider(repository: repo);
    await provider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(body: DetailSheet(view: repo.value)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('收藏时间'));
    await tester.tap(find.text('收藏时间'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    return repo;
  }

  testWidgets('点击收藏时间修改日期后即时展示，保留备注和标签', (tester) async {
    final repo = await show(tester);
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(repo.value.createdAt, startsWith('2026-11-01'));
    expect(repo.value.note, sample('date').note);
    expect(repo.value.secondaryTags, sample('date').secondaryTags);
    expect(find.text('2026年11月01日'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('取消不写入，保存失败保留原日期并显示提示', (tester) async {
    final repo = await show(tester);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    repo.fail = true;
    await tester.tap(find.text('收藏时间'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.value.createdAt, '2026-11-02');
    expect(find.text('2026年11月02日'), findsOneWidget);
    expect(find.text('保存失败，请重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
