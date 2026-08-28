import 'package:flutter/material.dart';

import '../models/primary_tag.dart';
import '../theme/colors.dart';

/// 地图 Pin：只显示线性图标（无圆泡、无尾巴）。
/// 已打卡 = 实色；待打卡 = 半透明。
class PinMarker extends StatelessWidget {
  final PrimaryTag tag;
  final bool visited;
  final double size;

  const PinMarker({
    super.key,
    required this.tag,
    required this.visited,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visited ? 1 : 0.5,
      child: Icon(tag.icon, size: size, color: AppColors.ink),
    );
  }
}
