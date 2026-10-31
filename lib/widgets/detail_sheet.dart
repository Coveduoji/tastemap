import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/collection_view.dart';
import '../data/poi_search.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/format.dart';
import 'edit_collection_sheet.dart';
import 'nav_picker.dart';
import 'sheet_chrome.dart';

/// Pin 详情 Sheet：名称 / 标签 / 我的备注 / 收藏时间 / 地址 + 底部编辑·导航·删除。
class DetailSheet extends StatelessWidget {
  final CollectionView view;
  final ScrollController? scrollController;
  final VoidCallback? onClose;
  final VoidCallback? onDetails;

  const DetailSheet({
    super.key,
    required this.view,
    this.scrollController,
    this.onClose,
    this.onDetails,
  });

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.pop(context, true);
    }
  }

  String get _addressText {
    if (view.place.address?.isNotEmpty == true) return view.place.address!;
    final parts = [
      view.city,
      view.country,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? '未标注地址' : parts.join(' · ');
  }

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<CollectionProvider>();
    // DDR-07：删除弹窗文案点名地点名，减少误删。
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除收藏'),
        content: Text('确认删除「${view.name}」？此操作不可恢复。'),
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
    if (confirmed != true) return;

    final ok = await provider.delete(view.id);
    if (!context.mounted) return;
    if (ok) {
      _close(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
    }
  }

  Future<void> _edit(BuildContext context) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCollectionSheet(view: view),
    );
    if (changed == true && context.mounted) {
      _close(context);
    }
  }

  Future<void> _nav(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => NavPickerSheet(view: view),
    );
  }

  Future<void> _copyAddress(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _addressText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ 地址已复制'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SheetContainer(
    child: ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.stone.withValues(alpha: .4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        InkWell(
          onTap:
              onDetails ??
              () => Navigator.pushNamed(
                context,
                '/place',
                arguments: Poi.fromPlace(view.place),
              ),
          child: Row(
            children: [
              Expanded(child: Text(view.name, style: AppText.placeName)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _dtag(
              view.tag.label,
              view.tag.bubbleColor,
              view.tag.accentColor,
              icon: view.tag.icon,
            ),
            ...view.secondaryTags.map(
              (t) => _dtag(t, AppColors.bg, AppColors.stone),
            ),
            if (view.visited)
              _dtag('已打卡', AppColors.visited, Colors.white, icon: Icons.check),
          ],
        ),
        const SizedBox(height: 16),
        if (view.images.isNotEmpty) ...[
          _photoStrip(),
          const SizedBox(height: 14),
        ],
        if (view.note.isNotEmpty) ...[
          Text(view.note, style: AppText.body),
          const SizedBox(height: 16),
        ],
        const Divider(height: 1, color: AppColors.divider),
        _InfoRow(
          icon: Icons.event,
          title: '收藏时间',
          subtitle: formatChineseDate(view.createdAt),
        ),
        _InfoRow(
          icon: Icons.location_on,
          title: _addressText,
          subtitle: '',
          onTap: () => _copyAddress(context),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _footBtn(
              Icons.edit,
              '编辑',
              AppColors.bg,
              AppColors.ink,
              .8,
              () => _edit(context),
            ),
            const SizedBox(width: 7),
            _footBtn(
              Icons.navigation,
              '导航前往',
              AppColors.accent,
              AppColors.warmWhite,
              1.4,
              () => _nav(context),
            ),
            const SizedBox(width: 7),
            _footBtn(
              Icons.delete_outline,
              '',
              AppColors.dangerBg,
              AppColors.danger,
              .7,
              () => _delete(context),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _photoStrip() {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: view.images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.file(
            File(view.images[i]),
            width: 120,
            height: 82,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 120,
              height: 82,
              color: AppColors.bg,
              child: const Icon(Icons.broken_image, color: AppColors.stone),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dtag(String label, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppText.chip.copyWith(color: fg, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _footBtn(
    IconData icon,
    String label,
    Color bg,
    Color fg,
    double flex,
    VoidCallback onTap,
  ) {
    return Expanded(
      flex: (flex * 10).round(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppText.chip.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Icon(icon, size: 17, color: AppColors.stone),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.stone, size: 18),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
