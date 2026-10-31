import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/collection_provider.dart';

import '../models/primary_tag.dart';
import '../models/secondary_tag.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/image_store.dart';

/// 收藏填写表单（一级标签 / 二级标签 / 打卡状态 / 备注），新建与编辑复用。
/// 通过 [CollectionFormFieldsState] 读取当前值（tag / secondaryTags / visited / note）。
class CollectionFormFields extends StatefulWidget {
  final PrimaryTag initialTag;
  final List<String> initialSecondaryTags;
  final bool initialVisited;
  final String initialNote;
  final List<String> initialImages;

  const CollectionFormFields({
    super.key,
    this.initialTag = PrimaryTag.food,
    this.initialSecondaryTags = const [],
    this.initialVisited = false,
    this.initialNote = '',
    this.initialImages = const [],
  });

  @override
  CollectionFormFieldsState createState() => CollectionFormFieldsState();
}

class CollectionFormFieldsState extends State<CollectionFormFields> {
  late PrimaryTag _tag;
  late Set<String> _secondaryTags;
  late bool _visited;
  late List<String> _images;
  late final TextEditingController _noteController;

  PrimaryTag get tag => _tag;
  List<String> get secondaryTags => _secondaryTags.toList();
  bool get visited => _visited;
  String get note => _noteController.text.trim();
  List<String> get images => List.unmodifiable(_images);

  @override
  void initState() {
    super.initState();
    _tag = widget.initialTag;
    _secondaryTags = widget.initialSecondaryTags.toSet();
    _visited = widget.initialVisited;
    _images = List.of(widget.initialImages);
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            ...{...provider.tagOptions, _tag}.map(
              (t) => _TagChip(
                tag: t,
                selected: _tag == t,
                onTap: () => setState(() => _tag = t),
                onDelete: t.isCustom ? () => _deleteOption(type: t) : null,
              ),
            ),
            _addButton('自定义类型', () => _addOption(true)),
          ],
        ),
        const SizedBox(height: 16),
        _StatusToggle(
          visited: _visited,
          onChanged: (v) => setState(() => _visited = v),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            ...{...provider.labelOptions, ..._secondaryTags}.map((label) {
              final selected = _secondaryTags.contains(label);
              return InputChip(
                label: Text(
                  label,
                  style: AppText.chip.copyWith(
                    color: selected ? Colors.white : AppColors.stone,
                  ),
                ),
                selected: selected,
                showCheckmark: false,
                onPressed: () => setState(() {
                  selected
                      ? _secondaryTags.remove(label)
                      : _secondaryTags.add(label);
                }),
                onDeleted: secondaryTagOptions.contains(label)
                    ? null
                    : () => _deleteOption(label: label),
                deleteIcon: Icon(
                  Icons.close,
                  size: 14,
                  color: selected ? Colors.white : AppColors.stone,
                ),
                deleteButtonTooltipMessage: '删除自定义标签',
                backgroundColor: AppColors.bg,
                selectedColor: AppColors.accent,
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }),
            _addButton('自定义标签', () => _addOption(false)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLength: 200,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '写点备注…',
            counterText: '',
            filled: true,
            fillColor: AppColors.warmWhite,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
          ),
          style: AppText.body,
        ),
        const SizedBox(height: 16),
        _imageSection(),
      ],
    );
  }

  Widget _addButton(String label, VoidCallback onTap) => ActionChip(
    avatar: const Icon(Icons.add, size: 16, color: AppColors.accent),
    label: Text(label, style: AppText.chip.copyWith(color: AppColors.accent)),
    onPressed: onTap,
    backgroundColor: AppColors.accentSoft,
    side: BorderSide.none,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Future<void> _deleteOption({PrimaryTag? type, String? label}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = type?.label ?? label!;
    final provider = context.read<CollectionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除“$name”？'),
        content: Text(
          type != null
              ? '将删除这个自定义类型，使用它的收藏改为“未分类”。收藏地点、备注和图片保留。'
              : '将从所有收藏中移除这个自定义标签，收藏地点保留。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = type != null
        ? await provider.removeType(type)
        : await provider.removeLabel(label!);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      return;
    }
    setState(() {
      if (type != null && _tag == type) _tag = PrimaryTag.other;
      if (label != null) _secondaryTags.remove(label);
    });
  }

  Future<void> _addOption(bool primary) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final provider = context.read<CollectionProvider>();
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(primary ? '自定义类型' : '自定义标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          decoration: InputDecoration(
            hintText: primary ? '例如：书店、公园' : '例如：适合独处、周末去',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(ctx, value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
    // Wait until the dialog has finished its exit animation before disposing its controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (!mounted || value == null) return;
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ');
    final tag = primary ? PrimaryTag.custom(normalized) : null;
    final ok = primary
        ? await provider.addType(tag!)
        : await provider.addLabel(normalized);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未能保存，请重试')));
      return;
    }
    setState(() {
      if (primary) {
        _tag = tag!;
      } else {
        _secondaryTags.add(normalized);
      }
    });
  }

  Future<void> _addImages() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final added = await ImageStore.pickAndSaveImages(
      fromCamera: choice == 'camera',
    );
    if (!mounted || added.isEmpty) return;
    setState(() {
      final remain = 3 - _images.length;
      if (remain > 0) _images.addAll(added.take(remain));
    });
  }

  Widget _imageSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._images.asMap().entries.map(
          (e) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(e.value),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.bg,
                    child: const Icon(
                      Icons.broken_image,
                      color: AppColors.stone,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 3,
                right: 3,
                child: GestureDetector(
                  onTap: () => setState(() => _images.removeAt(e.key)),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_images.length < 3)
          GestureDetector(
            onTap: _addImages,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.stone.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.stone,
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final PrimaryTag tag;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.bg,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tag.icon,
              size: 16,
              color: selected ? AppColors.warmWhite : AppColors.ink,
            ),
            const SizedBox(width: 6),
            Text(
              tag.label,
              style: AppText.chip.copyWith(
                color: selected ? AppColors.warmWhite : AppColors.ink,
              ),
            ),
            if (onDelete != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Semantics(
                  button: true,
                  label: '删除自定义类型${tag.label}',
                  child: GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: selected ? Colors.white : AppColors.stone,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final bool visited;
  final ValueChanged<bool> onChanged;

  const _StatusToggle({required this.visited, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          _stBtn('待打卡', !visited, () => onChanged(false)),
          _stBtn('已打卡 ✓', visited, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _stBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.warmWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppText.chip.copyWith(
              color: active ? AppColors.ink : AppColors.stone,
            ),
          ),
        ),
      ),
    );
  }
}
