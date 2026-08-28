import 'package:flutter/material.dart';

import '../models/primary_tag.dart';
import '../theme/colors.dart';

/// 地图 Pin：emoji 圆泡 + 底部三角尾。
/// 已打卡 = 实心气泡；待打卡 = 半透明 + 描边（设计稿的虚线边框简化为描边，P1 再补虚线）。
class PinMarker extends StatelessWidget {
  final PrimaryTag tag;
  final bool visited;
  final double size;

  const PinMarker({
    super.key,
    required this.tag,
    required this.visited,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final bubble =
        visited ? tag.bubbleColor : tag.bubbleColor.withValues(alpha: 0.4);
    final borderColor = visited ? Colors.transparent : AppColors.stone;
    final tailColor =
        visited ? tag.bubbleColor : tag.bubbleColor.withValues(alpha: 0.35);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bubble,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: visited ? 1 : 0.7,
            child: Text(
              tag.emoji,
              style: TextStyle(fontSize: size * 0.48),
            ),
          ),
        ),
        CustomPaint(
          size: Size(size * 0.32, size * 0.2),
          painter: _TailPainter(tailColor),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;

  const _TailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) => old.color != color;
}
