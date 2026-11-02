import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../data/import_service.dart';
import '../models/collection_view.dart';
import '../state/collection_provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _busy = false;
  String? _result;

  Future<void> _pick() async {
    if (_busy) return;
    final provider = context.read<CollectionProvider>();
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );
      if (file == null || !mounted) return;
      const maxBytes = 20 * 1024 * 1024;
      final length = await file.length();
      if (length != null && length > maxBytes) {
        throw const FormatException('请选择 20 MB 以内的文件');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        throw const FormatException('请选择 20 MB 以内的文件');
      }
      final parsed = ImportService.decode(
        bytes,
        csv: file.name.toLowerCase().endsWith('.csv'),
      );
      final imageDir = path.join(
        (await getApplicationDocumentsDirectory()).path,
        'images',
      );
      final views = <CollectionView>[];
      var missing = 0;
      for (final view in parsed) {
        final images = <String>[];
        for (final image in view.images) {
          if (path.isWithin(imageDir, image) && await File(image).exists()) {
            images.add(image);
          } else {
            missing++;
          }
        }
        views.add(
          CollectionView(
            place: view.place,
            collection: view.collection.copyWith(images: images),
          ),
        );
      }
      if (!mounted) return;
      if (views.isEmpty) {
        setState(() => _result = '文件中没有收藏');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('合并导入'),
          content: Text(
            '读取到 ${views.length} 条收藏。已有记录保留，重复记录跳过。'
            '${missing > 0 ? '\n$missing 张照片无法在本机找到，将只导入其地点与文字。' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('导入'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final result = await provider.mergeImport(views);
      if (mounted) {
        setState(
          () => _result = '已导入 ${result.added} 条，跳过 ${result.skipped} 条重复收藏',
        );
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(
          () => _result = RegExp(r'[\u4e00-\u9fff]').hasMatch(e.message)
              ? e.message
              : '文件格式不正确，请选择拾途导出的 JSON 或 CSV',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _result = '导入失败，现有收藏未被替换，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('导入数据')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('选择拾途导出的 JSON 或 CSV，合并到现有收藏。'),
        const SizedBox(height: 12),
        const Text('文件不含照片原图；跨设备导入无法恢复照片。'),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.file_open_outlined),
          label: const Text('选择文件'),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(_result!),
          ),
      ],
    ),
  );
}
