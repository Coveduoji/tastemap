import 'dart:io';

import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('类型 *'),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: PrimaryTag.values
              .map((t) => _TagChip(
                    tag: t,
                    selected: _tag == t,
                    onTap: () => setState(() => _tag = t),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('打卡状态'),
        _StatusToggle(
          visited: _visited,
          onChanged: (v) => setState(() => _visited = v),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('二级标签（选填）'),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: secondaryTagOptions.map((label) {
            final selected = _secondaryTags.contains(label);
            return GestureDetector(
              onTap: () => setState(() {
                selected
                    ? _secondaryTags.remove(label)
                    : _secondaryTags.add(label);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selected ? AppColors.ink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  label,
                  style: AppText.chip.copyWith(
                    color: selected ? AppColors.ink : AppColors.stone,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('备注（选填）'),
        TextField(
          controller: _noteController,
          maxLength: 200,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '加了个人记忆的锚点...',
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
        const _FieldLabel('图片（选填，最多 3 张）'),
        _imageSection(),
      ],
    );
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
        ..._images.asMap().entries.map((e) => Stack(
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
                      child: const Icon(Icons.broken_image,
                          color: AppColors.stone),
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
                      child: const Icon(Icons.close,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),
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
                    color: AppColors.stone.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.add_a_photo_outlined,
                  color: AppColors.stone),
            ),
          ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text, style: AppText.label.copyWith(letterSpacing: 0.1)),
    );
  }
}

class _TagChip extends StatelessWidget {
  final PrimaryTag tag;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: tag.bubbleColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          '${tag.emoji} ${tag.label}',
          style: AppText.chip.copyWith(color: tag.accentColor),
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
