import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/collection_view.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'sheet_chrome.dart';

/// 导航选择器：跳转高德 / Google / Apple 地图或拷贝地址（DDR-05：不自建导航）。
class NavPickerSheet extends StatelessWidget {
  final CollectionView view;

  const NavPickerSheet({super.key, required this.view});

  String get _addr {
    return [
      view.name,
      view.place.address,
      view.city,
      view.country,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
  }

  Future<void> _launch(BuildContext context, String app, Uri uri) async {
    Navigator.pop(context);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _toast(context, '无法打开 $app');
    } catch (_) {
      if (context.mounted) _toast(context, '无法打开 $app');
    }
  }

  Future<void> _copy(BuildContext context) async {
    Navigator.pop(context);
    await Clipboard.setData(ClipboardData(text: _addr));
    if (context.mounted) _toast(context, '✓ 地址已复制');
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = view.latitude;
    final lng = view.longitude;
    final encodedName = Uri.encodeComponent(view.name);

    return SheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                Text('前往', style: AppText.caption),
                const SizedBox(height: 3),
                Text(
                  _addr,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _NavItem(
            icon: Icons.map,
            bg: AppColors.bg,
            title: '高德地图',
            subtitle: '',
            onTap: () => _launch(
              context,
              '高德地图',
              Uri.parse(
                'https://uri.amap.com/navigation?to=$lng,$lat,$encodedName&mode=car',
              ),
            ),
          ),
          _NavItem(
            icon: Icons.public,
            bg: AppColors.bg,
            title: 'Google Maps',
            subtitle: '',
            onTap: () => _launch(
              context,
              'Google Maps',
              Uri.parse(
                'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
              ),
            ),
          ),
          _NavItem(
            icon: Icons.explore,
            bg: AppColors.bg,
            title: 'Apple 地图',
            subtitle: '',
            isLast: true,
            onTap: () => _launch(
              context,
              'Apple 地图',
              Uri.parse('https://maps.apple.com/?daddr=$lat,$lng'),
            ),
          ),
          const SizedBox(height: 8),
          _CopyItem(onTap: () => _copy(context)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.warmWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '取消',
                style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _NavItem({
    required this.icon,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.dividerLight)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: AppColors.ink),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.stone, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CopyItem extends StatelessWidget {
  final VoidCallback onTap;

  const _CopyItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.content_copy,
                size: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 13),
            Text(
              '拷贝地址',
              style: AppText.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
