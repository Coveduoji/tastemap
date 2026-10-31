import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/collection_view.dart';

class ExportService {
  static ({Uint8List bytes, String filename, String mime}) encode(
    List<CollectionView> views, {
    required bool csv,
  }) {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    if (!csv) {
      final value = {
        'version': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'places': views.map((v) => v.place.toMap()).toList(),
        'collections': views.map((v) => v.collection.toMap()).toList(),
      };
      return (
        bytes: Uint8List.fromList(
          utf8.encode(const JsonEncoder.withIndent('  ').convert(value)),
        ),
        filename: 'TasteMap-$date.json',
        mime: 'application/json',
      );
    }
    Object cell(Object value) =>
        value is String && RegExp(r'^[=+@-]').hasMatch(value)
        ? "'$value"
        : value;
    final rows = <List<Object>>[
      [
        '地点',
        '国家',
        '省',
        '城市',
        '区',
        '地址',
        '纬度',
        '经度',
        '类型',
        '标签',
        '已打卡',
        '备注',
        '收藏时间',
      ],
      ...views.map(
        (v) => <Object>[
          v.name,
          v.country ?? '',
          v.place.province ?? '',
          v.city ?? '',
          v.place.district ?? '',
          v.place.address ?? '',
          v.latitude,
          v.longitude,
          v.tag.label,
          v.secondaryTags.join(' | '),
          v.visited ? '是' : '否',
          v.note,
          v.createdAt,
        ].map(cell).toList(),
      ),
    ];
    final content = const ListToCsvConverter().convert(rows);
    return (
      bytes: Uint8List.fromList([0xef, 0xbb, 0xbf, ...utf8.encode(content)]),
      filename: 'TasteMap-$date.csv',
      mime: 'text/csv',
    );
  }
}
