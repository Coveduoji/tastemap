import 'package:flutter/material.dart';

/// TasteMap 设计令牌 —— 色彩规范（唯一权威来源，界面不得硬编码色值）。
/// 来源：TasteMap_Design.md §01 设计系统。
class AppColors {
  AppColors._();

  // ── 主色 ──
  static const Color ink = Color(0xFF2D2A26); // 主文字 / FAB / 主 CTA
  static const Color warmWhite = Color(0xFFF5F0E8); // 页面背景 / 卡片
  static const Color terracotta = Color(0xFFB8906A); // 强调色 / 高亮
  static const Color stone = Color(0xFF8C8880); // 次要文字

  // ── 分类强调色（饱和，用于文字/深色强调） ──
  static const Color food = Color(0xFFE07040); // 🍜 美食
  static const Color coffee = Color(0xFFA07850); // ☕ 咖啡
  static const Color hotel = Color(0xFF4878CC); // 🏨 酒店
  static const Color sight = Color(0xFF3A9C58); // 📷 景点
  static const Color bar = Color(0xFF9048B8); // 🍸 酒吧

  // ── Pin 气泡底色（浅色调） ──
  static const Color foodBubble = Color(0xFFFFDFC8);
  static const Color coffeeBubble = Color(0xFFEDE0D0);
  static const Color hotelBubble = Color(0xFFD8E8FC);
  static const Color sightBubble = Color(0xFFD8F0E0);
  static const Color barBubble = Color(0xFFEDD8F4);

  // ── 语义色 ──
  static const Color danger = Color(0xFFC04040); // 删除（非纯红）
  static const Color dangerBg = Color(0xFFFDDCD8);
  static const Color visited = Color(0xFF3A9C58); // 已打卡
  static const Color pending = Color(0xFFB8906A); // 待打卡
  static const Color locationBlue = Color(0xFF4878CC); // 定位点

  // ── 背景 / 描边 ──
  static const Color bg = Color(0xFFEDEAE4); // 画布背景（设计稿 body 背景）
  static const Color mapBg = Color(0xFFE9E5DC); // 地图占位底色
  static const Color divider = Color(0xFFE8E2DA);
  static const Color dividerLight = Color(0xFFECEAE3);
  static const Color cardBorder = Color(0xFFE0DAD0);
}
