import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import '../models/collection.dart';
import '../models/collection_view.dart';
import '../models/place.dart';
import '../models/primary_tag.dart';
import '../utils/uuid.dart';

/// File codecs use the same models as export; imports never replace local data.
class ImportService {
  static List<CollectionView> decode(List<int> bytes, {required bool csv}) {
    try {
      final text = utf8.decode(bytes).replaceFirst(RegExp(r'^\uFEFF'), '');
      final views = csv ? _csv(text) : _json(text);
      for (final view in views) {
        if (view.id.isEmpty ||
            view.placeId.isEmpty ||
            view.name.trim().isEmpty ||
            !view.latitude.isFinite ||
            !view.longitude.isFinite ||
            view.latitude.abs() > 90 ||
            view.longitude.abs() > 180 ||
            !['visited', 'pending'].contains(view.visitedStatus)) {
          throw const FormatException('地点名称、坐标或打卡状态不正确');
        }
      }
      return views;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('文件格式不正确，请选择拾途导出的 JSON 或 CSV');
    }
  }

  static List<CollectionView> _json(String text) {
    final raw = jsonDecode(text);
    if (raw is! Map ||
        raw['places'] is! List ||
        raw['collections'] is! List ||
        (raw['version'] != null && ![1, 2].contains(raw['version']))) {
      throw const FormatException('不支持的备份格式或版本');
    }
    final places = <String, Place>{};
    for (final row in raw['places'] as List) {
      final place = Place.fromMap((row as Map).cast<String, Object?>());
      if (places.containsKey(place.id)) {
        throw const FormatException('文件中存在重复地点编号');
      }
      places[place.id] = place;
    }
    final ids = <String>{};
    return (raw['collections'] as List).map((row) {
      final map = (row as Map).cast<String, Object?>();
      for (final field in ['secondary_tags', 'images']) {
        final value = map[field];
        if (value != null) {
          final decoded = value is String ? jsonDecode(value) : value;
          if (decoded is! List || decoded.any((v) => v is! String)) {
            throw const FormatException('标签或照片数据格式不正确');
          }
          map[field] = jsonEncode(decoded);
        }
      }
      final tag = map['primary_tag'];
      if (tag is! String ||
          !(PrimaryTag.values.any((t) => t.name == tag) ||
              tag == 'other' ||
              (tag.startsWith('custom:') &&
                  PrimaryTag.fromName(tag).isCustom))) {
        throw const FormatException('收藏类型不正确');
      }
      final collection = Collection.fromMap(map);
      final place = places[collection.placeId];
      if (place == null || !ids.add(collection.id)) {
        throw const FormatException('收藏缺少对应地点或编号重复');
      }
      return CollectionView(place: place, collection: collection);
    }).toList();
  }

  static List<CollectionView> _csv(String text) {
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      allowInvalid: false,
      csvSettingsDetector: FirstOccurrenceSettingsDetector(
        eols: ['\r\n', '\n', '\r'],
      ),
    ).convert(text);
    if (rows.isEmpty) throw const FormatException('文件为空');
    final headers = rows.first.map((v) => '$v').toList();
    if (!['地点', '纬度', '经度'].every(headers.contains) ||
        headers.toSet().length != headers.length) {
      throw const FormatException('CSV 缺少地点、纬度或经度列');
    }
    String unescape(String value) =>
        RegExp(r"^'[=+@-]").hasMatch(value) ? value.substring(1) : value;
    return rows.skip(1).where((r) => r.any((v) => '$v'.isNotEmpty)).map((row) {
      if (row.length != headers.length) {
        throw const FormatException('CSV 列数不一致');
      }
      String cell(String label) {
        final i = headers.indexOf(label);
        return i < 0 ? '' : unescape('${row[i]}');
      }

      final name = cell('地点');
      final latitude = double.tryParse(cell('纬度'));
      final longitude = double.tryParse(cell('经度'));
      if (latitude == null || longitude == null) {
        throw const FormatException('CSV 坐标不正确');
      }
      final label = cell('类型');
      final tag = label.isEmpty || label == PrimaryTag.other.label
          ? PrimaryTag.other
          : PrimaryTag.custom(label);
      final visited = cell('已打卡');
      if (!['', '是', '否'].contains(visited)) {
        throw const FormatException('已打卡列应填写是或否');
      }
      final place = Place(
        id: generateId(),
        name: name,
        latitude: latitude,
        longitude: longitude,
        country: cell('国家'),
        province: cell('省'),
        city: cell('城市'),
        district: cell('区'),
        address: cell('地址'),
        createdAt: cell('收藏时间'),
        source: 'import',
      );
      return CollectionView(
        place: place,
        collection: Collection(
          id: generateId(),
          placeId: place.id,
          primaryTag: tag,
          secondaryTags: cell(
            '标签',
          ).split(' | ').where((s) => s.isNotEmpty).toList(),
          note: cell('备注'),
          visitedStatus: visited == '是' ? 'visited' : 'pending',
          createdAt: cell('收藏时间'),
          updatedAt: cell('收藏时间'),
        ),
      );
    }).toList();
  }

  static String _fingerprint(CollectionView view) => jsonEncode([
    view.name,
    view.latitude.toStringAsFixed(6),
    view.longitude.toStringAsFixed(6),
    view.tag.name,
    [...view.secondaryTags]..sort(),
    view.note,
    view.visitedStatus,
    view.createdAt,
  ]);

  static ({List<CollectionView> additions, int skipped}) planMerge(
    List<CollectionView> incoming,
    List<CollectionView> existing,
  ) {
    final ids = existing.map((v) => v.id).toSet();
    final fingerprints = existing.map(_fingerprint).toSet();
    final additions = <CollectionView>[];
    final places = <String, Place>{};
    var skipped = 0;
    for (final view in incoming) {
      final fingerprint = _fingerprint(view);
      if (ids.contains(view.id) || fingerprints.contains(fingerprint)) {
        skipped++;
        continue;
      }
      final place = places.putIfAbsent(
        view.placeId,
        () => Place.fromMap({...view.place.toMap(), 'id': generateId()}),
      );
      additions.add(
        CollectionView(
          place: place,
          collection: Collection.fromMap({
            ...view.collection.toMap(),
            'place_id': place.id,
          }),
        ),
      );
      ids.add(view.id);
      fingerprints.add(fingerprint);
    }
    return (additions: additions, skipped: skipped);
  }
}
