import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../data/mock_pois.dart';
import '../models/collection.dart';
import '../models/place.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/uuid.dart';
import 'collection_form_fields.dart';
import 'sheet_chrome.dart';

/// 收藏流程 Sheet：Step 1 附近地点列表 → Step 2 填写表单（共享同一容器，DDR-03）。
class PoiSheet extends StatefulWidget {
  final LatLng center;

  const PoiSheet({super.key, required this.center});

  @override
  State<PoiSheet> createState() => _PoiSheetState();
}

class _PoiSheetState extends State<PoiSheet> {
  int _step = 0; // 0 = 列表，1 = 填写
  String _name = '';
  String _addr = '';
  double _lat = 0;
  double _lng = 0;
  final _formKey = GlobalKey<CollectionFormFieldsState>();

  void _select(MockPoi poi) {
    setState(() {
      _name = poi.name;
      _addr = poi.addr;
      _lat = poi.latitude;
      _lng = poi.longitude;
      _step = 1;
    });
  }

  Future<void> _manualInput() async {
    final name = await _promptName();
    if (name == null || name.isEmpty) return;
    setState(() {
      _name = name;
      _addr = '手动标记';
      _lat = widget.center.latitude;
      _lng = widget.center.longitude;
      _step = 1;
    });
  }

  Future<String?> _promptName() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动输入地点名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入地点名称...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;
    final now = nowIso8601();
    final place = Place(
      id: generateId(),
      name: _name,
      latitude: _lat,
      longitude: _lng,
      type: 'custom',
      createdAt: now,
    );
    final collection = Collection(
      id: generateId(),
      placeId: place.id,
      primaryTag: form.tag,
      secondaryTags: form.secondaryTags,
      note: form.note,
      images: form.images,
      visitedStatus: form.visited ? 'visited' : 'pending',
      createdAt: now,
      updatedAt: now,
    );
    final ok = await context.read<CollectionProvider>().save(place, collection);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请检查存储空间后重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      child: _step == 0 ? _buildList() : _buildForm(),
    );
  }

  Widget _buildList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('附近地点', style: AppText.sectionTitle),
                        const SizedBox(height: 3),
                        Text('选择你想收藏的地点 · 按距离排序', style: AppText.caption),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Text('×',
                          style: TextStyle(fontSize: 20, color: AppColors.stone)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 搜索框（P0 占位，接入 Foursquare 后启用）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text('搜索地点名称...', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.divider),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: mockPois.length,
            itemBuilder: (_, i) => _PoiItem(
              poi: mockPois[i],
              onTap: () => _select(mockPois[i]),
            ),
          ),
        ),
        _ManualEntry(onTap: _manualInput),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _step = 0),
                      child: Text('← 重新选择',
                          style: AppText.chip.copyWith(color: AppColors.hotel)),
                    ),
                    const Spacer(),
                    Text('第 2 步 · 共 2 步', style: AppText.caption),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_name, style: AppText.placeName),
                const SizedBox(height: 2),
                Text(_addr, style: AppText.caption),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 16),
                CollectionFormFields(key: _formKey),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _SaveButton(onTap: _save, label: '保存收藏'),
          ),
        ],
      ),
    );
  }
}

class _PoiItem extends StatelessWidget {
  final MockPoi poi;
  final VoidCallback onTap;

  const _PoiItem({required this.poi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: poi.tag.bubbleColor,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(poi.tag.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poi.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(poi.addr, style: AppText.caption),
                ],
              ),
            ),
            Text(poi.distance,
                style: AppText.chip.copyWith(color: AppColors.terracotta)),
          ],
        ),
      ),
    );
  }
}

class _ManualEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _ManualEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: const Text('📍', style: TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 11),
            Text('找不到？',
                style: AppText.body.copyWith(color: AppColors.stone)),
            const SizedBox(width: 4),
            Text('手动输入地点名称',
                style: AppText.chip.copyWith(color: AppColors.hotel)),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _SaveButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(label,
            style: AppText.chip
                .copyWith(color: AppColors.warmWhite, fontSize: 14)),
      ),
    );
  }
}
