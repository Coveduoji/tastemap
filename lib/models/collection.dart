import 'dart:convert';

import 'primary_tag.dart';

/// 收藏记录（PRD §7.2 Collection 表）。
class Collection {
  final String id;
  final String placeId;
  final PrimaryTag primaryTag;
  final List<String> secondaryTags;
  final String note;
  final List<String> images;
  final String visitedStatus; // 'pending' | 'visited'
  final String createdAt;
  final String updatedAt;

  const Collection({
    required this.id,
    required this.placeId,
    required this.primaryTag,
    this.secondaryTags = const [],
    this.note = '',
    this.images = const [],
    this.visitedStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get visited => visitedStatus == 'visited';

  Collection copyWith({
    PrimaryTag? primaryTag,
    List<String>? secondaryTags,
    String? note,
    List<String>? images,
    String? visitedStatus,
    String? updatedAt,
  }) =>
      Collection(
        id: id,
        placeId: placeId,
        primaryTag: primaryTag ?? this.primaryTag,
        secondaryTags: secondaryTags ?? this.secondaryTags,
        note: note ?? this.note,
        images: images ?? this.images,
        visitedStatus: visitedStatus ?? this.visitedStatus,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'place_id': placeId,
        'primary_tag': primaryTag.name,
        'secondary_tags': jsonEncode(secondaryTags),
        'note': note,
        'images': jsonEncode(images),
        'visited_status': visitedStatus,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Collection.fromMap(Map<String, Object?> map) => Collection(
        id: map['id'] as String,
        placeId: map['place_id'] as String,
        primaryTag: PrimaryTag.fromName(map['primary_tag'] as String?),
        secondaryTags: _decodeList(map['secondary_tags']),
        note: (map['note'] as String?) ?? '',
        images: _decodeList(map['images']),
        visitedStatus: (map['visited_status'] as String?) ?? 'pending',
        createdAt: (map['created_at'] as String?) ?? '',
        updatedAt: (map['updated_at'] as String?) ?? '',
      );

  static List<String> _decodeList(Object? raw) {
    if (raw == null || raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {
      // 容错：损坏的 JSON 视为空列表
    }
    return const [];
  }
}
