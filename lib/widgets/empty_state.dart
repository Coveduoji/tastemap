import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 首次使用提示：说明收藏入口，避免空地图缺少操作指引。
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.warmWhite.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 36,
              color: AppColors.accent,
            ),
            SizedBox(height: 14),
            Text(
              '世界很大，从喜欢开始',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '轻点下方 +，收藏你的第一个地点',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.stone),
            ),
          ],
        ),
      ),
    );
  }
}
