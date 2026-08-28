import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 底部弹层的统一外观：圆角顶 + 拖拽手柄。各 Sheet 复用，避免重复样式。
class SheetContainer extends StatelessWidget {
  final Widget child;

  const SheetContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// 顶部拖拽手柄（灰色小横条）。
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 11, bottom: 5),
      child: Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.stone.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
