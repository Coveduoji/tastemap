import 'package:flutter/material.dart';
import '../models/collection_view.dart';

enum MemoryCardStyle {
  minimal('留白'),
  dark('夜色'),
  color('取色'),
  quote('短句'),
  full('全幅'),
  collage('双图');

  const MemoryCardStyle(this.label);
  final String label;
}

/// A photo-led layout rendered identically in the preview and saved image.
class ShareMemoryCard extends StatelessWidget {
  final CollectionView view;
  final MemoryCardStyle style;
  final List<ImageProvider> photos;
  final Color color;
  final bool showNote, showCity;
  const ShareMemoryCard({
    super.key,
    required this.view,
    required this.style,
    this.photos = const [],
    this.color = const Color(0xFFDDE7E3),
    this.showNote = true,
    this.showCity = true,
  });

  Widget _fallbackCover() => SizedBox.expand(
    child: ColoredBox(
      color: const Color(0xFFEDF3FF),
      child: LayoutBuilder(
        builder: (_, bounds) => Padding(
          padding: EdgeInsets.all(bounds.biggest.shortestSide * .22),
          child: Image.asset(
            'assets/app_icons/wander.png',
            fit: BoxFit.contain,
            semanticLabel: '默认旅行封面',
          ),
        ),
      ),
    ),
  );

  Widget _photo(int index, {BoxFit fit = BoxFit.cover}) => photos.isEmpty
      ? _fallbackCover()
      : Image(
          image: photos[index.clamp(0, photos.length - 1)],
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _fallbackCover(),
        );

  Widget _brand(Color ink) => Row(
    children: [
      Image.asset('assets/app_icons/wander.png', width: 15, height: 15),
      const SizedBox(width: 5),
      Text(
        '拾途',
        style: TextStyle(
          fontSize: 10,
          color: ink.withValues(alpha: .65),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  String get _city => [
    view.place.province,
    view.city,
    view.place.district,
  ].whereType<String>().where((s) => s.isNotEmpty).toSet().take(2).join(' · ');

  Widget _title(Color ink, {double size = 23}) => Text(
    view.name,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: size,
      height: 1.2,
      letterSpacing: -.5,
      color: ink,
      fontWeight: FontWeight.w600,
    ),
  );
  Widget _region(Color ink) => showCity && _city.isNotEmpty
      ? Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              color: ink.withValues(alpha: .6),
            ),
          ),
        )
      : const SizedBox.shrink();
  Widget _note(Color ink, {double size = 13, int lines = 3}) =>
      showNote && view.note.trim().isNotEmpty
      ? Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            view.note.trim(),
            maxLines: lines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size,
              height: 1.6,
              color: ink.withValues(alpha: .88),
              fontWeight: size > 20 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        )
      : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: LayoutBuilder(
      builder: (_, bounds) => FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(width: 360, height: 480, child: _layout()),
      ),
    ),
  );

  Widget _layout() {
    final bg = switch (style) {
      MemoryCardStyle.dark || MemoryCardStyle.full => const Color(0xFF151A20),
      MemoryCardStyle.color => color,
      MemoryCardStyle.quote => const Color(0xFFEDEBE4),
      _ => Colors.white,
    };
    final ink = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : const Color(0xFF171B22);
    if (style == MemoryCardStyle.full) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _photo(0),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xEE000000)],
                stops: [.25, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                _title(Colors.white, size: 28),
                _region(Colors.white),
                _note(Colors.white, lines: 4),
                const SizedBox(height: 24),
                _brand(Colors.white),
              ],
            ),
          ),
        ],
      );
    }
    if (style == MemoryCardStyle.quote) {
      return ColoredBox(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_title(ink, size: 19), _region(ink)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 88, height: 88, child: _photo(0)),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: showNote && view.note.trim().isNotEmpty
                      ? _note(ink, size: 27, lines: 7)
                      : _title(ink, size: 36),
                ),
              ),
              _brand(ink),
            ],
          ),
        ),
      );
    }
    final compact = style == MemoryCardStyle.color;
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 248 : 260,
              child: style == MemoryCardStyle.collage && photos.length > 1
                  ? Row(
                      children: [
                        Expanded(child: _photo(0)),
                        const SizedBox(width: 6),
                        Expanded(child: _photo(1)),
                      ],
                    )
                  : compact
                  ? Center(child: SizedBox(width: 248, child: _photo(0)))
                  : _photo(0),
            ),
            const SizedBox(height: 20),
            _title(ink),
            _region(ink),
            Expanded(
              child: LayoutBuilder(
                builder: (_, bounds) => Align(
                  alignment: Alignment.topLeft,
                  child: _note(
                    ink,
                    lines: ((bounds.maxHeight - 12) / 21).floor().clamp(1, 3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _brand(ink),
          ],
        ),
      ),
    );
  }
}
