import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/secondary_tag.dart';

import '../data/collection_repository.dart';
import '../models/collection.dart';
import '../models/collection_view.dart';
import '../models/place.dart';
import '../models/primary_tag.dart';

/// 收藏数据的状态管理（Provider / ChangeNotifier）。
/// 持有全量收藏 + 当前筛选标签，向地图 / Profile 等界面广播变化。
class CollectionProvider extends ChangeNotifier {
  final CollectionRepository _repo;
  CollectionProvider({CollectionRepository? repository})
    : _repo = repository ?? CollectionRepository();
  bool nearbyReminders = false;
  Future<bool> setPreference(String key, String value) async {
    if (!await _repo.setSetting(key, value)) return false;
    if (key == 'nearby_reminders') nearbyReminders = value == '1';
    notifyListeners();
    return true;
  }

  Future<bool> claimFirstMapTip() async {
    try {
      if (await _repo.getSetting('map_tip_seen') == '1') return false;
      await _repo.setSetting('map_tip_seen', '1');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> enrichPlace(Place place) async {
    if (await _repo.updatePlace(place)) await load();
  }

  List<PrimaryTag> _customTypes = [];
  List<String> _customLabels = [];
  List<PrimaryTag> get tagOptions => {
    ...PrimaryTag.values,
    ..._customTypes,
    ..._all.map((v) => v.tag),
  }.toList();
  List<String> get labelOptions => {
    ...secondaryTagOptions,
    ..._customLabels,
    ..._all.expand((v) => v.secondaryTags),
  }.toList();

  Future<bool> addType(PrimaryTag tag) async {
    if (tagOptions.contains(tag)) return true;
    final next = [..._customTypes, tag];
    if (!await _repo.setSetting(
      'custom_types',
      jsonEncode(next.map((t) => t.name).toList()),
    )) {
      return false;
    }
    _customTypes = next;
    notifyListeners();
    return true;
  }

  Future<bool> addLabel(String label) async {
    if (labelOptions.contains(label)) return true;
    final next = [..._customLabels, label];
    if (!await _repo.setSetting('custom_labels', jsonEncode(next))) {
      return false;
    }
    _customLabels = next;
    notifyListeners();
    return true;
  }

  Future<bool> removeType(PrimaryTag tag) async {
    if (!tag.isCustom) return false;
    final remaining = _customTypes
        .where((t) => t != tag)
        .map((t) => t.name)
        .toList();
    if (!await _repo.removeCustomType(tag, remaining)) return false;
    if (_selectedTag == tag) _selectedTag = null;
    await load();
    return true;
  }

  Future<bool> removeLabel(String label) async {
    if (secondaryTagOptions.contains(label)) return false;
    final remaining = _customLabels.where((t) => t != label).toList();
    if (!await _repo.removeCustomLabel(label, remaining)) return false;
    await load();
    return true;
  }

  Future<List<String>> _readOptions(String key) async {
    try {
      final raw = jsonDecode(await _repo.getSetting(key) ?? '[]');
      return raw is List
          ? raw.whereType<String>().where((s) => s.trim().isNotEmpty).toList()
          : [];
    } catch (_) {
      return [];
    }
  }

  List<CollectionView> _all = [];
  bool _loaded = false;
  PrimaryTag? _selectedTag;

  List<CollectionView> get all => _all;
  bool get loaded => _loaded;
  PrimaryTag? get selectedTag => _selectedTag;

  /// 按当前筛选标签过滤后的列表（null = 全部）。
  List<CollectionView> get filtered => _selectedTag == null
      ? _all
      : _all.where((v) => v.tag == _selectedTag).toList();

  Future<void> load() async {
    try {
      _all = await _repo.getCollectionViews();
    } catch (_) {
      // Web 等无原生 SQLite 的平台：降级为空列表，避免启动崩溃
      _all = [];
    }
    _customTypes = (await _readOptions(
      'custom_types',
    )).map(PrimaryTag.fromName).toSet().toList();
    _customLabels = await _readOptions('custom_labels');
    try {
      nearbyReminders = await _repo.getSetting('nearby_reminders') == '1';
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  void setTag(PrimaryTag? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  Future<bool> save(Place place, Collection collection) async {
    final ok = await _repo.save(place, collection);
    if (ok) await load();
    return ok;
  }

  Future<bool> update(Collection collection) async {
    final ok = await _repo.update(collection);
    if (ok) await load();
    return ok;
  }

  Future<bool> delete(String collectionId) async {
    final ok = await _repo.delete(collectionId);
    if (ok) await load();
    return ok;
  }

  Future<bool> deleteAll() async {
    final ok = await _repo.deleteAll();
    if (ok) await load();
    return ok;
  }

  /// 云同步恢复：用云端数据整体替换本地。
  Future<bool> importAll(
    List<Place> places,
    List<Collection> collections,
  ) async {
    final ok = await _repo.importAll(places, collections);
    if (ok) await load();
    return ok;
  }

  /// 统计数字（收藏数 / 城市数 / 国家数），Profile 用。
  Future<Map<String, int>> stats() => _repo.getStats();
}
