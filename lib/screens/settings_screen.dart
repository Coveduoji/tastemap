import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'webdav_screen.dart';

/// 设置页（Profile 右上角三横线进入）。P0 为静态壳，仅「清除所有收藏」可触发。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearAll(BuildContext context) async {
    final provider = context.read<CollectionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有收藏'),
        content: const Text('此操作不可逆，将删除全部收藏数据。确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await provider.deleteAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已清除所有收藏' : '清除失败，请重试')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                  ),
                  const SizedBox(width: 6),
                  Text('更多', style: AppText.sectionTitle.copyWith(fontSize: 16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _label('数据与同步'),
                  _item(Icons.cloud_sync, AppColors.bg, '坚果云同步', 'WebDAV 备份 / 恢复',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const WebDavScreen()))),
                  _item(Icons.file_upload, AppColors.bg, '导出数据', '导出为 JSON / CSV'),
                  _label('应用'),
                  _item(Icons.map, AppColors.bg, '地图设置', '默认地图类型 · 缓存'),
                  _item(Icons.notifications_none, AppColors.bg, '通知', '附近收藏提醒'),
                  _label('关于'),
                  _item(Icons.info_outline, AppColors.bg, '版本信息', 'TasteMap v1.0.0'),
                  _item(Icons.chat_bubble_outline, AppColors.bg, '和开发者聊聊', '反馈问题 · 提建议'),
                  _item(Icons.menu_book, AppColors.bg, '使用说明', '长按 + · 同步配置'),
                  _label('数据管理'),
                  _dangerItem(Icons.delete_outline, '清除所有收藏', '操作不可逆，请谨慎',
                      () => _clearAll(context)),
                  const SizedBox(height: 24),
                  Text(
                    'TasteMap · v1.0.0 · 把你喜欢的地方，钉在地图上',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: AppColors.stone),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 5),
      child: Text(text, style: AppText.label.copyWith(letterSpacing: 0.1)),
    );
  }

  Widget _item(IconData icon, Color bg, String title, String subtitle,
      [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: AppColors.ink),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
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

  Widget _dangerItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: AppColors.danger),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.body
                          .copyWith(fontWeight: FontWeight.w500, color: AppColors.danger)),
                  const SizedBox(height: 2),
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
