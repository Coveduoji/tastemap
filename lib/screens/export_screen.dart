import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/export_service.dart';
import '../state/collection_provider.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _csv = false, _busy = false;
  Future<void> _export(bool share) async {
    setState(() => _busy = true);
    try {
      final output = ExportService.encode(
        context.read<CollectionProvider>().all,
        csv: _csv,
      );
      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                output.bytes,
                mimeType: output.mime,
                name: output.filename,
              ),
            ],
            fileNameOverrides: [output.filename],
            title: '品味地图',
          ),
        );
      } else {
        final uri = await FilePicker.saveFile(
          fileName: output.filename,
          bytes: output.bytes,
          mimeType: output.mime,
        );
        if (uri != null && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已保存')));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导出失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('导出数据')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('JSON')),
              ButtonSegment(value: true, label: Text('CSV')),
            ],
            selected: {_csv},
            onSelectionChanged: (values) =>
                setState(() => _csv = values.single),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : () => _export(false),
            icon: const Icon(Icons.save_alt),
            label: const Text('保存到文件'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _export(true),
            icon: const Icon(Icons.share_outlined),
            label: const Text('分享'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    ),
  );
}
