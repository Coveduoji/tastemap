import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 一级标签：美食 / 咖啡 / 酒店 / 景点 / 酒吧。
/// 决定地图 Pin 的线性图标与图标底色（PRD §6.3 地图视觉规范）。
enum PrimaryTag {
  food(Icons.restaurant, '美食'),
  coffee(Icons.local_cafe, '咖啡'),
  hotel(Icons.hotel, '酒店'),
  sight(Icons.photo_camera, '景点'),
  bar(Icons.local_bar, '酒吧');

  const PrimaryTag(this.icon, this.label);

  final IconData icon;
  final String label;

  /// Pin/列表图标底色：分类不再各配一个饱和色块，统一中性面——颜色只留给强调色。
  Color get bubbleColor => AppColors.bg;

  /// 分类文字色：统一主文字色，区分靠线性图标而非色相。
  Color get accentColor => AppColors.ink;

  /// 按枚举名解析，未知值兜底到 food。
  static PrimaryTag fromName(String? name) => PrimaryTag.values.firstWhere(
        (t) => t.name == name,
        orElse: () => PrimaryTag.food,
      );
}
