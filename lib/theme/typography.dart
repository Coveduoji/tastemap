import 'package:flutter/material.dart';

import 'colors.dart';

/// TasteMap 设计令牌 —— 字体与字号。
/// 使用平台系统无衬线字体，中文依次回退到苹方与 Noto Sans。
/// 不额外打包字体，保持应用体积与平台字体渲染表现。
class AppFonts {
  AppFonts._();

  static const String serif = sans;
  static const String sans = '.AppleSystemUIFont';
}

/// 常用文字样式。UI 层优先引用这里，避免散落魔法数字。
class AppText {
  AppText._();

  static const TextStyle _serif = TextStyle(
    fontFamily: AppFonts.serif,
    fontFamilyFallback: ['PingFang SC', 'Noto Sans CJK SC', 'Roboto'],
    color: AppColors.ink,
  );
  static const TextStyle _sans = TextStyle(
    fontFamily: AppFonts.sans,
    fontFamilyFallback: ['PingFang SC', 'Noto Sans CJK SC', 'Roboto'],
    color: AppColors.ink,
  );

  // 地点名 / 标题类
  static TextStyle get placeName =>
      _serif.copyWith(fontSize: 19, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get cityName =>
      _serif.copyWith(fontSize: 17, fontWeight: FontWeight.w700, height: 1.25);
  static TextStyle get sectionTitle =>
      _serif.copyWith(fontSize: 18, fontWeight: FontWeight.w700);
  static TextStyle get profileNick =>
      _serif.copyWith(fontSize: 24, fontWeight: FontWeight.w700);

  // 功能性文字（无衬线）
  static TextStyle get label => _sans.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.stone,
  );
  static TextStyle get caption =>
      _sans.copyWith(fontSize: 12, color: AppColors.stone);
  static TextStyle get body =>
      _sans.copyWith(fontSize: 15, color: AppColors.ink, height: 1.6);
  static TextStyle get chip =>
      _sans.copyWith(fontSize: 13, fontWeight: FontWeight.w500);
}
