import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 无收藏时的空态：仅显示一个定位标记线性图标，无文字（用户要简洁）。
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.location_on, size: 44, color: AppColors.stone),
    );
  }
}
