import 'package:flutter/material.dart';

/// 无收藏时的空态：仅显示一个 📍 定位标记，无文字（用户要简洁）。
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('📍', style: TextStyle(fontSize: 44)),
    );
  }
}
