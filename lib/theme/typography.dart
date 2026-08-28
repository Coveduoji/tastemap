import 'package:flutter/material.dart';

import 'colors.dart';

/// TasteMap 设计令牌 —— 字体与字号。
/// 设计规范：Noto Serif SC（地点名/城市名/昵称）、DM Sans（功能性文字）。
///
/// P0 策略：中文衬线复用 Android 系统内置的 Noto Serif CJK SC，无衬线复用默认 Roboto，
/// 避免捆绑体积庞大的字体文件；Web 端自动回退到系统衬线/无衬线。
class AppFonts {
  AppFonts._();

  static const String serif = 'Noto Serif CJK SC';
  static const String sans = 'Roboto';
}

/// 常用文字样式。UI 层优先引用这里，避免散落魔法数字。
class AppText {
  AppText._();

  static const TextStyle _serif = TextStyle(
    fontFamily: AppFonts.serif,
    color: AppColors.ink,
  );
  static const TextStyle _sans = TextStyle(
    fontFamily: AppFonts.sans,
    color: AppColors.ink,
  );

  // 地点名 / 标题类（衬线）
  static TextStyle get placeName => _serif.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );
  static TextStyle get cityName => _serif.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1,
      );
  static TextStyle get sectionTitle => _serif.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get profileNick => _serif.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );

  // 功能性文字（无衬线）
  static TextStyle get label => _sans.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.stone,
      );
  static TextStyle get caption => _sans.copyWith(
        fontSize: 10,
        color: AppColors.stone,
      );
  static TextStyle get body => _sans.copyWith(
        fontSize: 12,
        color: AppColors.ink,
        height: 1.6,
      );
  static TextStyle get chip => _sans.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );
}
