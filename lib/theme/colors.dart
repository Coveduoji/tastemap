import 'package:flutter/material.dart';

/// TasteMap 设计令牌 —— 色彩规范（唯一权威来源，界面不得硬编码色值）。
/// 柔和灰底、白色卡片与清爽蓝色；分类色退场为中性图标层，
/// 颜色只留给需要被看见的东西——按钮、FAB、选中态。
class AppColors {
  AppColors._();

  // ── 主色 ──
  static const Color ink = Color(0xFF1C2333); // 主文字 / 次要图标
  static const Color warmWhite = Color(0xFFFFFFFF); // 页面背景 / 卡片 / 按钮文字
  static const Color accent = Color(
    0xFF3478F6,
  ); // 清爽蓝：唯一强调色 / FAB / 主 CTA / 选中态
  static const Color accentDeep = Color(0xFF2459BD); // 强调色深色（按压态）
  static const Color accentSoft = Color(0xFFEAF1FF); // 强调色浅底（选中态背景/徽标底）
  static const Color stone = Color(0xFF7B8495); // 次要文字

  static const Color mapFavorite = Color(0xFFFFC928); // 明黄色收藏及聚合标记

  // ── 语义色 ──
  static const Color danger = Color(0xFFC04040); // 删除（非纯红）
  static const Color dangerBg = Color(0xFFFDDCD8);
  static const Color visited = Color(0xFF3A9C58); // 已打卡
  static const Color pending = Color(0xFFA6ABB4); // 待打卡（中性灰，非分类色）

  // ── 背景 / 描边 ──
  static const Color bg = Color(0xFFF3F5F9); // 输入框 / 占位块 / 中性面（非分类色）
  static const Color divider = Color(0xFFEBEBEE);
  static const Color dividerLight = Color(0xFFF1F1F3);
  static const Color cardBorder = Color(0xFFE7E7EA);
}
