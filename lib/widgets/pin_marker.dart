import 'package:flutter/material.dart';

import '../models/primary_tag.dart';
import '../theme/colors.dart';

/// 地图 Pin：白边圆形标记；实蓝表示已打卡，白底蓝图标表示待打卡。
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
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: visited ? AppColors.accent : AppColors.warmWhite,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.warmWhite, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        tag.icon,
        size: size * 0.6,
        color: visited ? AppColors.warmWhite : AppColors.accent,
      ),
    );
  }
}

class FavoriteMarker extends StatelessWidget {
  final String name;
  final PrimaryTag tag;
  final bool visited;
  const FavoriteMarker({
    super.key,
    required this.name,
    required this.tag,
    required this.visited,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 28,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
      SizedBox(
        height: 28,
        child: Center(
          child: Container(
            width: 1,
            color: AppColors.stone.withValues(alpha: .45),
          ),
        ),
      ),
      PinMarker(tag: tag, visited: visited, size: 30),
    ],
  );
}
