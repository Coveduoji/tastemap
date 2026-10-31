import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tastemap/data/collection_repository.dart';
import 'package:tastemap/models/collection.dart';
import 'package:tastemap/models/collection_view.dart';
import 'package:tastemap/models/primary_tag.dart';
import 'package:tastemap/state/collection_provider.dart';
import 'package:tastemap/widgets/collection_form_fields.dart';

class MemoryRepository extends CollectionRepository {
  final settings = <String, String>{};
  @override
  Future<List<CollectionView>> getCollectionViews() async => [];
  @override
  Future<String?> getSetting(String key) async => settings[key];
  @override
  Future<bool> setSetting(String key, String value) async {
    settings[key] = value;
    return true;
  }
}

void main() {
  test('自定义类型跨序列化保持名称、相等性与旧数据兼容', () {
    final type = PrimaryTag.custom('  书店 / 展览  ');
    final collection = Collection(
      id: 'c',
      placeId: 'p',
      primaryTag: type,
      secondaryTags: ['适合独处'],
      createdAt: '',
      updatedAt: '',
    );
    final restored = Collection.fromMap(collection.toMap());
    expect(restored.primaryTag, type);
    expect(restored.primaryTag.label, '书店 / 展览');
    expect(restored.secondaryTags, ['适合独处']);
    expect(PrimaryTag.custom('美食'), PrimaryTag.food);
    expect(PrimaryTag.fromName('custom:'), PrimaryTag.food);
    expect(PrimaryTag.fromName('coffee'), PrimaryTag.coffee);
  });

  test('新类型与标签重载后仍可复用，不会重复追加', () async {
    final repo = MemoryRepository();
    final first = CollectionProvider(repository: repo);
    final tag = PrimaryTag.custom('书店');
    expect(await first.addType(tag), isTrue);
    expect(await first.addType(tag), isTrue);
    expect(await first.addLabel('适合独处'), isTrue);
    final reloaded = CollectionProvider(repository: repo);
    await reloaded.load();
    expect(reloaded.tagOptions.where((t) => t == tag).length, 1);
    expect(reloaded.labelOptions, contains('适合独处'));
    first.dispose();
    reloaded.dispose();
  });

  testWidgets('原位置末尾的按钮新增类型和标签，并自动选中', (tester) async {
    final provider = CollectionProvider(repository: MemoryRepository());
    final formKey = GlobalKey<CollectionFormFieldsState>();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CollectionFormFields(key: formKey),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(ActionChip, '自定义类型'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '书店');
    await tester.tap(find.widgetWithText(TextButton, '添加'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.tag, PrimaryTag.custom('书店'));
    await tester.ensureVisible(find.widgetWithText(ActionChip, '自定义标签'));
    await tester.tap(find.widgetWithText(ActionChip, '自定义标签'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '适合独处');
    await tester.tap(find.widgetWithText(TextButton, '添加'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.secondaryTags, contains('适合独处'));
    expect(tester.takeException(), isNull);
  });
}
