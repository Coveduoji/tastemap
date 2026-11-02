import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/collection_view.dart';
import 'share_memory_card.dart';

Future<void> showShareCard(BuildContext context, CollectionView view) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: ShareCardSheet(view: view),
      ),
    );

class ShareCardSheet extends StatefulWidget {
  final CollectionView view;
  const ShareCardSheet({super.key, required this.view});
  @override
  State<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<ShareCardSheet> {
  final _capture = ScreenshotController();
  final _preview = GlobalKey();
  MemoryCardStyle _style = MemoryCardStyle.minimal;
  int _cover = 0;
  bool _showNote = true, _showCity = true, _busy = false;
  Color _color = const Color(0xFFDCE8FF);

  List<ImageProvider> get _photos =>
      widget.view.images.map((p) => FileImage(File(p))).toList();
  List<ImageProvider> get _orderedPhotos {
    final photos = _photos;
    if (photos.isEmpty) return photos;
    return [
      photos[_cover],
      ...photos.indexed.where((e) => e.$1 != _cover).map((e) => e.$2),
    ];
  }

  @override
  void initState() {
    super.initState();
    _extractColor();
  }

  Future<void> _extractColor() async {
    final photos = _photos;
    final cover = _cover;
    if (photos.isEmpty) return;
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: photos[cover],
      );
      if (mounted && cover == _cover) {
        setState(() => _color = scheme.primaryContainer);
      }
    } catch (_) {
      /* Missing photos use a neutral background. */
    }
  }

  Future<void> _output(bool share) async {
    if (_busy) return;
    final box = context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _busy = true);
    try {
      final exportPhotos = _orderedPhotos.isEmpty
          ? <ImageProvider>[const AssetImage('assets/app_icons/wander.png')]
          : _orderedPhotos.take(_style == MemoryCardStyle.collage ? 2 : 1);
      for (final photo in exportPhotos) {
        if (!mounted) return;
        await precacheImage(photo, context, onError: (_, _) {});
      }
      if (!mounted) return;
      final width = _preview.currentContext!.size!.width;
      final bytes = await _capture.capture(pixelRatio: 1080 / width);
      if (bytes == null || !mounted) return;
      final basename = 'ShiTu-${DateTime.now().millisecondsSinceEpoch}';
      final filename = '$basename.png';
      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(bytes, mimeType: 'image/png')],
            fileNameOverrides: [filename],
            title: widget.view.name,
            sharePositionOrigin: origin,
          ),
        );
      } else {
        if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
          if (mounted) _message('请允许保存到相册');
          return;
        }
        if (!mounted) return;
        await Gal.putImageBytes(bytes, name: basename);
        if (mounted) _message('已保存到相册');
      }
    } catch (_) {
      if (mounted) _message(share ? '分享失败，请重试' : '保存失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '分享回忆',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Screenshot(
                  controller: _capture,
                  child: SizedBox.expand(
                    key: _preview,
                    child: ShareMemoryCard(
                      view: widget.view,
                      style: _style,
                      photos: _orderedPhotos,
                      color: _color,
                      showNote: _showNote,
                      showCity: _showCity,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        AbsorbPointer(
          absorbing: _busy,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    for (final style in MemoryCardStyle.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(style.label),
                          selected: _style == style,
                          onSelected: (_) => setState(() => _style = style),
                        ),
                      ),
                  ],
                ),
              ),
              if (_photos.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < _photos.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('照片 ${i + 1}'),
                            selected: _cover == i,
                            onSelected: (_) {
                              setState(() => _cover = i);
                              _extractColor();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              Wrap(
                spacing: 10,
                children: [
                  FilterChip(
                    label: const Text('备注'),
                    selected: _showNote,
                    onSelected: (value) => setState(() => _showNote = value),
                  ),
                  FilterChip(
                    label: const Text('城市'),
                    selected: _showCity,
                    onSelected: (value) => setState(() => _showCity = value),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _output(false),
                        icon: const Icon(Icons.save_alt),
                        label: const Text('保存图片'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _output(true),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('分享'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
      ],
    ),
  );
}
