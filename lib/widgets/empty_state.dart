import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

/// 无收藏时的空态引导（PRD §10：新用户首次启动不显示空白地图）。
class EmptyState extends StatelessWidget {
  final VoidCallback? onAdd;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    this.onAdd,
    this.title = '把你的第一个喜欢的地方，钉在地图上',
    this.subtitle = '点击下方 + 开始收藏',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.warmWhite,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('📍', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.sectionTitle),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppText.caption,
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.warmWhite,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('+ 添加收藏'),
            ),
          ],
        ],
      ),
    );
  }
}
