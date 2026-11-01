import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

Future<void> showPhotoViewer(
  BuildContext context, {
  required List<ImageProvider> images,
  int initialIndex = 0,
}) async {
  if (images.isEmpty) return;
  FocusScope.of(context).unfocus();
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewer(
        images: List.unmodifiable(images),
        initialIndex: initialIndex.clamp(0, images.length - 1),
      ),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  final List<ImageProvider> images;
  final int initialIndex;
  const _PhotoViewer({required this.images, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: const CloseButton(),
      centerTitle: true,
      title: Text('${_index + 1} / ${widget.images.length}'),
    ),
    body: SafeArea(
      top: false,
      child: PhotoViewGallery.builder(
        pageController: _pages,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _index = index),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, _) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        builder: (_, index) => PhotoViewGalleryPageOptions(
          imageProvider: widget.images[index],
          minScale: PhotoViewComputedScale.contained,
          initialScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.contained * 5,
          errorBuilder: (_, _, _) => const Center(
            child: Text('照片无法加载', style: TextStyle(color: Colors.white70)),
          ),
        ),
      ),
    ),
  );
}
