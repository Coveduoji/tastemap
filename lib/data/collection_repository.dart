import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/collection.dart';
import '../models/collection_view.dart';
import '../models/place.dart';
import '../models/primary_tag.dart';
import 'database.dart';
import 'import_service.dart';

/// 收藏数据的持久化访问层。所有写操作都返回是否成功，供 UI 层做失败提示。
class CollectionRepository {
  static const _secure = FlutterSecureStorage();
  final AppDatabase _db = AppDatabase.instance;

  /// 查询全部收藏（JOIN 地点），按收藏时间倒序。
  Future<List<CollectionView>> getCollectionViews() async {
    final db = await _db.database;
    return _collectionViews(db);
  }

  Future<List<CollectionView>> _collectionViews(DatabaseExecutor db) async {
    final rows = await db.rawQuery('''
      SELECT
        c.id, c.place_id, c.primary_tag, c.secondary_tags, c.note, c.images,
        c.visited_status, c.created_at, c.updated_at,
        p.name, p.latitude, p.longitude, p.city, p.country, p.province, p.district, p.adcode, p.amap_id, p.address,
        p.type, p.source, p.foursquare_id
      FROM collections c
      JOIN places p ON p.id = c.place_id
      ORDER BY c.created_at DESC
    ''');
    return rows.map(CollectionView.fromRow).toList();
  }

  Future<bool> updatePlace(Place place) async {
    try {
      final db = await _db.database;
      return await db.update(
            'places',
            place.toMap(),
            where: 'id = ?',
            whereArgs: [place.id],
          ) ==
          1;
    } catch (_) {
      return false;
    }
  }

  /// 按一级标签筛选。
  Future<List<CollectionView>> getByTag(PrimaryTag tag) async {
    final all = await getCollectionViews();
    return all.where((v) => v.tag == tag).toList();
  }

  /// 统计数字（收藏数 / 城市数 / 国家数），供 Profile 使用。
  Future<Map<String, int>> getStats() async {
    final views = await getCollectionViews();
    final cities = views.map((v) => v.city).whereType<String>().toSet();
    final countries = views.map((v) => v.country).whereType<String>().toSet();
    return {
      'collections': views.length,
      'cities': cities.length,
      'countries': countries.length,
    };
  }

  /// 保存收藏：地点 + 收藏记录在同一事务内写入。
  Future<bool> save(Place place, Collection collection) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.insert(
          'places',
          place.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.insert(
          'collections',
          collection.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 更新收藏记录（标签/备注/打卡状态等）。
  Future<bool> update(Collection collection) async {
    try {
      final db = await _db.database;
      final changed = await db.update(
        'collections',
        collection.toMap(),
        where: 'id = ?',
        whereArgs: [collection.id],
      );
      return changed == 1;
    } catch (_) {
      return false;
    }
  }

  /// Delete one memory; shared places remain until their last collection is removed.
  Future<bool> delete(String collectionId) async {
    try {
      final db = await _db.database;
      return await db.transaction((tx) async {
        final placeId = await _placeIdOf(tx, collectionId);
        if (placeId == null) return false;
        await tx.delete(
          'collections',
          where: 'id = ?',
          whereArgs: [collectionId],
        );
        await tx.rawDelete(
          'DELETE FROM places WHERE id = ? AND NOT EXISTS '
          '(SELECT 1 FROM collections WHERE place_id = ?)',
          [placeId, placeId],
        );
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  /// 清空所有收藏（设置页「清除所有收藏」）。
  Future<bool> deleteAll() async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete('collections');
        await txn.delete('places');
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _placeIdOf(DatabaseExecutor db, String collectionId) async {
    final rows = await db.query(
      'collections',
      columns: ['place_id'],
      where: 'id = ?',
      whereArgs: [collectionId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['place_id'] as String?;
  }

  /// 导出：所有地点（供云同步全量备份）。
  Future<List<Place>> getAllPlaces() async {
    final db = await _db.database;
    final rows = await db.query('places');
    return rows.map(Place.fromMap).toList();
  }

  /// 导入：用云端数据整体替换本地（云同步恢复）。
  Future<bool> importAll(
    List<Place> places,
    List<Collection> collections,
  ) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete('collections');
        await txn.delete('places');
        for (final p in places) {
          await txn.insert('places', p.toMap());
        }
        for (final c in collections) {
          await txn.insert('collections', c.toMap());
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<({int added, int skipped})> mergeImport(
    List<CollectionView> incoming,
  ) async {
    final db = await _db.database;
    return db.transaction((tx) async {
      final plan = ImportService.planMerge(
        incoming,
        await _collectionViews(tx),
      );
      final insertedPlaces = <String>{};
      for (final view in plan.additions) {
        if (insertedPlaces.add(view.placeId)) {
          await tx.insert('places', view.place.toMap());
        }
        await tx.insert('collections', view.collection.toMap());
      }
      return (added: plan.additions.length, skipped: plan.skipped);
    });
  }

  /// Update assignments and reusable options atomically; never remove places.
  Future<bool> removeCustomType(PrimaryTag tag, List<String> remaining) async {
    if (!tag.isCustom) return false;
    try {
      final db = await _db.database;
      await db.transaction((tx) async {
        await tx.update(
          'collections',
          {
            'primary_tag': PrimaryTag.other.name,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'primary_tag = ?',
          whereArgs: [tag.name],
        );
        await tx.insert('app_settings', {
          'key': 'custom_types',
          'value': jsonEncode(remaining),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeCustomLabel(String label, List<String> remaining) async {
    try {
      final db = await _db.database;
      await db.transaction((tx) async {
        final rows = await tx.query(
          'collections',
          columns: ['id', 'secondary_tags'],
        );
        for (final row in rows) {
          List<String> labels;
          try {
            labels = (jsonDecode(row['secondary_tags'] as String) as List)
                .cast<String>();
          } catch (_) {
            continue;
          }
          if (!labels.contains(label)) continue;
          await tx.update(
            'collections',
            {
              'secondary_tags': jsonEncode(
                labels.where((v) => v != label).toList(),
              ),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
        await tx.insert('app_settings', {
          'key': 'custom_labels',
          'value': jsonEncode(remaining),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 读配置项（App_Settings 表）。
  Future<String?> getSetting(String key) async {
    final db = await _db.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    final legacy = rows.isEmpty ? null : rows.first['value'] as String?;
    if (key == 'webdav_password') {
      if (legacy != null) {
        await _secure.write(key: key, value: legacy);
        await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
      }
      return _secure.read(key: key);
    }
    return legacy;
  }

  /// 写配置项（App_Settings 表）。
  Future<bool> setSetting(String key, String value) async {
    try {
      if (key == 'webdav_password') {
        await _secure.write(key: key, value: value);
        return true;
      }
      final db = await _db.database;
      await db.insert('app_settings', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (_) {
      return false;
    }
  }
}
