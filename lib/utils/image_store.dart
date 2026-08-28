import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 图片选择 + 压缩 + 保存到应用私有目录。
/// 压缩至 ≤800px 长边、JPEG 质量 85，控制本地存储体积（PRD §5.2）。
class ImageStore {
  /// 从相册或相机选择图片并保存，返回压缩后的本地路径（每次最多 3 张）。
  /// 相册权限被拒 / 读取失败时返回空列表，不抛异常、不阻断收藏保存。
  static Future<List<String>> pickAndSaveImages({
    required bool fromCamera,
  }) async {
    final List<XFile> picked;
    try {
      final picker = ImagePicker();
      if (fromCamera) {
        final f = await picker.pickImage(source: ImageSource.camera);
        picked = f == null ? const [] : [f];
      } else {
        picked = await picker.pickMultiImage();
      }
    } catch (_) {
      return const []; // 权限被拒或选择失败：静默降级
    }
    if (picked.isEmpty) return const [];

    final dir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(dir.path, 'images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final saved = <String>[];
    final now = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < picked.length && saved.length < 3; i++) {
      try {
        final target = p.join(imageDir.path, '${now}_$i.jpg');
        final result = await FlutterImageCompress.compressAndGetFile(
          picked[i].path,
          target,
          minWidth: 800,
          minHeight: 800,
          quality: 85,
        );
        if (result != null) saved.add(result.path);
      } catch (_) {
        // 单张图片压缩失败：跳过，继续处理下一张
      }
    }
    return saved;
  }
}
