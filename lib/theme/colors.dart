import 'package:flutter/material.dart';

/// TasteMap 设计令牌 —— 色彩规范（唯一权威来源，界面不得硬编码色值）。
/// 白底 + 单一强调色（朱红）+ 大色块的视觉方向：分类色退场为中性图标层，
/// 颜色只留给需要被看见的东西——按钮、FAB、选中态。
class AppColors {
  AppColors._();

  // ── 主色 ──
  static const Color ink = Color(0xFF14151A); // 主文字 / 次要图标
  static const Color warmWhite = Color(0xFFFFFFFF); // 页面背景 / 卡片 / 按钮文字
  static const Color accent = Color(0xFFE8402A); // 朱红：唯一强调色 / FAB / 主 CTA / 选中态
  static const Color accentDeep = Color(0xFFA62A18); // 强调色深色（按压态）
  static const Color accentSoft = Color(0xFFFDE7E2); // 强调色浅底（选中态背景/徽标底）
  static const Color stone = Color(0xFF797D86); // 次要文字

  // ── 语义色 ──
  static const Color danger = Color(0xFFC04040); // 删除（非纯红）
  static const Color dangerBg = Color(0xFFFDDCD8);
  static const Color visited = Color(0xFF3A9C58); // 已打卡
  static const Color pending = Color(0xFFA6ABB4); // 待打卡（中性灰，非分类色）

  // ── 背景 / 描边 ──
  static const Color bg = Color(0xFFF3F4F6); // 输入框 / 占位块 / 中性面（非分类色）
  static const Color divider = Color(0xFFEBEBEE);
  static const Color dividerLight = Color(0xFFF1F1F3);
  static const Color cardBorder = Color(0xFFE7E7EA);
}
