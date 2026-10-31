import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Built-in names remain stable in SQLite and backups; custom names are self-describing.
@immutable
class PrimaryTag {
  final String name;
  final IconData icon;
  final String label;
  const PrimaryTag._(this.name, this.icon, this.label);

  static const food = PrimaryTag._('food', Icons.restaurant, '美食');
  static const coffee = PrimaryTag._('coffee', Icons.local_cafe, '咖啡');
  static const hotel = PrimaryTag._('hotel', Icons.hotel, '酒店');
  static const sight = PrimaryTag._('sight', Icons.photo_camera, '景点');
  static const bar = PrimaryTag._('bar', Icons.local_bar, '酒吧');
  static const values = [food, coffee, hotel, sight, bar];

  factory PrimaryTag.custom(String label) {
    final value = label.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty || value.length > 24) {
      throw ArgumentError('类型名称需为 1–24 个字符');
    }
    for (final tag in values) {
      if (tag.label.toLowerCase() == value.toLowerCase()) return tag;
    }
    return PrimaryTag._(
      'custom:${Uri.encodeComponent(value)}',
      Icons.label_outline_rounded,
      value,
    );
  }

  static const other = PrimaryTag._('other', Icons.bookmark_outline, '未分类');
  bool get isCustom => name.startsWith('custom:');

  Color get bubbleColor => AppColors.bg;
  Color get accentColor => AppColors.ink;
  static PrimaryTag fromName(String? name) {
    if (name == other.name) return other;
    for (final tag in values) {
      if (tag.name == name) return tag;
    }
    if (name != null && name.startsWith('custom:')) {
      try {
        return PrimaryTag.custom(Uri.decodeComponent(name.substring(7)));
      } on ArgumentError {
        return food;
      }
    }
    return food;
  }

  @override
  bool operator ==(Object other) => other is PrimaryTag && name == other.name;
  @override
  int get hashCode => name.hashCode;
}
