import 'package:flutter/material.dart';

import '../models/primary_tag.dart';
import '../theme/colors.dart';

/// 收藏标记使用明黄色圆角五角星。
class PinMarker extends StatelessWidget {
  final PrimaryTag tag;
  final bool visited;
  final double size;

  const PinMarker({
    super.key,
    required this.tag,
    required this.visited,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      size: size,
      color: AppColors.mapFavorite,
      shadows: const [
        Shadow(color: Colors.white, offset: Offset(-1, -1)),
        Shadow(color: Colors.white, offset: Offset(1, -1)),
        Shadow(color: Colors.white, offset: Offset(-1, 1)),
        Shadow(color: Colors.white, offset: Offset(1, 1)),
      ],
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
            border: Border.all(color: AppColors.mapFavorite, width: 1.5),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: const Offset(0, -1),
            child: CustomPaint(size: const Size(12, 9), painter: _BubbleTip()),
          ),
        ),
      ),
      PinMarker(tag: tag, visited: visited, size: 40),
    ],
  );
}

class _BubbleTip extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.mapFavorite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BubbleTip oldDelegate) => false;
}
