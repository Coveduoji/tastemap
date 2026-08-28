import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 一级标签：美食 / 咖啡 / 酒店 / 景点 / 酒吧。
/// 决定地图 Pin 的 emoji 与气泡颜色（PRD §6.3 地图视觉规范）。
enum PrimaryTag {
  food('🍜', '美食'),
  coffee('☕', '咖啡'),
  hotel('🏨', '酒店'),
  sight('📷', '景点'),
  bar('🍸', '酒吧');

  const PrimaryTag(this.emoji, this.label);

  final String emoji;
  final String label;

  /// Pin 气泡底色（浅色调）。
  Color get bubbleColor {
    switch (this) {
      case PrimaryTag.food:
        return AppColors.foodBubble;
      case PrimaryTag.coffee:
        return AppColors.coffeeBubble;
      case PrimaryTag.hotel:
        return AppColors.hotelBubble;
      case PrimaryTag.sight:
        return AppColors.sightBubble;
      case PrimaryTag.bar:
        return AppColors.barBubble;
    }
  }

  /// 分类强调色（饱和，用于文字/标签）。
  Color get accentColor {
    switch (this) {
      case PrimaryTag.food:
        return AppColors.food;
      case PrimaryTag.coffee:
        return AppColors.coffee;
      case PrimaryTag.hotel:
        return AppColors.hotel;
      case PrimaryTag.sight:
        return AppColors.sight;
      case PrimaryTag.bar:
        return AppColors.bar;
    }
  }

  /// 按枚举名解析，未知值兜底到 food。
  static PrimaryTag fromName(String? name) => PrimaryTag.values.firstWhere(
        (t) => t.name == name,
        orElse: () => PrimaryTag.food,
      );
}
