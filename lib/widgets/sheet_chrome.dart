import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Styling only. Dragging and dismissal are provided by Flutter's BottomSheet.
class SheetContainer extends StatelessWidget {
  final Widget child;
  const SheetContainer({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: SafeArea(top: false, child: child),
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(height: 8);
}
