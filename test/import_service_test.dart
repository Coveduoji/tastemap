import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tastemap/data/collection_repository.dart';
import 'package:tastemap/data/database.dart';
import 'package:tastemap/data/export_service.dart';
import 'package:tastemap/data/import_service.dart';
import 'package:tastemap/models/collection.dart';
import 'package:tastemap/models/collection_view.dart';
import 'package:tastemap/models/place.dart';
import 'package:tastemap/models/primary_tag.dart';

CollectionView sample(String id, {String note = '多行\n备注,"晴天"'}) =>
    CollectionView(
      place: Place(
        id: 'p$id',
        name: '=公开地标',
        latitude: 39.99,
        longitude: 116.27,
        province: '北京',
        city: '北京',
        district: '海淀',
        createdAt: '2026-11-02',
      ),
      collection: Collection(
        id: id,
        placeId: 'p$id',
        primaryTag: PrimaryTag.custom('旅行'),
        secondaryTags: const ['宁静', '湖边'],
        note: note,
        visitedStatus: 'visited',
        createdAt: '2026-11-02',
        updatedAt: '2026-11-02',
      ),
    );
void main() {
  test('JSON/CSV往返保留文字、标签、坐标和行政区，重复导入可识别', () {
    final original = sample('a');
    for (final csv in [false, true]) {
      final views = ImportService.decode(
        ExportService.encode([original], csv: csv).bytes,
        csv: csv,
      );
      expect(views.single.name, original.name);
      expect(views.single.note, original.note);
      expect(views.single.tag, original.tag);
      expect(views.single.secondaryTags, original.secondaryTags);
      expect(views.single.place.district, '海淀');
      expect(views.single.visited, isTrue);
      expect(ImportService.planMerge(views, [original]).skipped, 1);
    }
  });
  test('坏坐标、引用缺失、重复编号与未来格式整批拒绝', () {
    final raw = jsonDecode(
      utf8.decode(ExportService.encode([sample('a')], csv: false).bytes),
    );
    raw['places'][0]['latitude'] = 999;
    expect(
      () => ImportService.decode(utf8.encode(jsonEncode(raw)), csv: false),
      throwsFormatException,
    );
    raw['places'][0]['latitude'] = 39;
    raw['collections'][0]['place_id'] = 'missing';
    expect(
      () => ImportService.decode(utf8.encode(jsonEncode(raw)), csv: false),
      throwsFormatException,
    );
    raw['collections'][0]['place_id'] = 'pa';
    raw['collections'].add(raw['collections'][0]);
    expect(
      () => ImportService.decode(utf8.encode(jsonEncode(raw)), csv: false),
      throwsFormatException,
    );
    raw['version'] = 999;
    expect(
      () => ImportService.decode(utf8.encode(jsonEncode(raw)), csv: false),
      throwsFormatException,
    );
  });
  test('已有ID保留，CSV不同记录不被误合并，跨表地点编号冲突不覆盖本地', () {
    final old = sample('a');
    expect(
      ImportService.planMerge([sample('a', note: '新内容')], [old]).skipped,
      1,
    );
    final plan = ImportService.planMerge([sample('b', note: '第二次来')], [old]);
    expect(plan.additions.length, 1);
    expect(plan.additions.single.placeId, isNot('pb'));
    expect(
      plan.additions.single.collection.placeId,
      plan.additions.single.place.id,
    );
  });
  group('SQLite 合并事务', () {
    late Directory temp;
    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      temp = await Directory.systemTemp.createTemp('shitu-import-');
      await databaseFactory.setDatabasesPath(temp.path);
    });
    tearDown(() async {
      await AppDatabase.instance.close();
      await temp.delete(recursive: true);
    });
    test('合并保留原收藏，重复导入跳过', () async {
      final repo = CollectionRepository();
      final old = sample('a');
      await repo.save(old.place, old.collection);
      final incoming = [sample('b', note: '另一条回忆')];
      expect(await repo.mergeImport(incoming), (added: 1, skipped: 0));
      expect(await repo.mergeImport(incoming), (added: 0, skipped: 1));
      final values = await repo.getCollectionViews();
      expect(values.length, 2);
      expect(values.singleWhere((v) => v.id == 'a').note, old.note);
    });
    test('同一地点的多条回忆只删除所选记录，最后一条删除后清理地点', () async {
      final repo = CollectionRepository();
      final first = sample('first');
      final second = CollectionView(
        place: first.place,
        collection: Collection(
          id: 'second',
          placeId: first.placeId,
          primaryTag: PrimaryTag.sight,
          note: '另一次旅行',
          createdAt: '2026-11-02',
          updatedAt: '2026-11-02',
        ),
      );
      await repo.mergeImport([first, second]);
      expect((await repo.getAllPlaces()).length, 1);
      expect(await repo.delete('first'), isTrue);
      expect((await repo.getCollectionViews()).single.id, 'second');
      expect((await repo.getAllPlaces()).length, 1);
      expect(await repo.delete('second'), isTrue);
      expect(await repo.getAllPlaces(), isEmpty);
    });
    test('修改收藏时间持久化并重新排序，保留其他数据和地点时间', () async {
      final repo = CollectionRepository();
      final first = sample('first');
      final second = sample('second');
      await repo.save(first.place, first.collection);
      await repo.save(second.place, second.collection);
      final edited = first.collection.copyWith(
        createdAt: '2020-01-02T10:30:00.000',
        updatedAt: '2026-11-02T12:00:00.000Z',
      );
      expect(await repo.update(edited), isTrue);
      final values = await repo.getCollectionViews();
      expect(values.map((v) => v.id), ['second', 'first']);
      expect(values.last.createdAt, edited.createdAt);
      expect(values.last.note, first.note);
      expect(values.last.images, first.images);
      expect(values.last.secondaryTags, first.secondaryTags);
      expect(
        (await repo.getAllPlaces())
            .firstWhere((p) => p.id == first.placeId)
            .createdAt,
        first.place.createdAt,
      );
      expect(await repo.update(sample('missing').collection), isFalse);
    });
    test('写入中途失败时整批回滚', () async {
      final repo = CollectionRepository();
      final old = sample('a');
      await repo.save(old.place, old.collection);
      final db = await AppDatabase.instance.database;
      await db.execute(
        "CREATE TRIGGER reject_test BEFORE INSERT ON collections WHEN NEW.id = 'bad' BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(
        repo.mergeImport([
          sample('good', note: '新增'),
          sample('bad', note: '失败'),
        ]),
        throwsA(anything),
      );
      expect((await repo.getCollectionViews()).map((v) => v.id), ['a']);
      expect((await repo.getAllPlaces()).length, 1);
    });
  });
}
