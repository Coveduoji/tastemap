import 'package:flutter/foundation.dart';

import '../data/collection_repository.dart';
import '../models/collection.dart';
import '../models/collection_view.dart';
import '../models/place.dart';
import '../models/primary_tag.dart';

/// 收藏数据的状态管理（Provider / ChangeNotifier）。
/// 持有全量收藏 + 当前筛选标签，向地图 / Profile 等界面广播变化。
class CollectionProvider extends ChangeNotifier {
  final CollectionRepository _repo = CollectionRepository();

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
  Future<bool> importAll(List<Place> places, List<Collection> collections) async {
    final ok = await _repo.importAll(places, collections);
    if (ok) await load();
    return ok;
  }

  /// 统计数字（收藏数 / 城市数 / 国家数），Profile 用。
  Future<Map<String, int>> stats() => _repo.getStats();
}
