import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/nearby_notifications.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import 'export_screen.dart';
import 'import_screen.dart';
import 'app_icon_screen.dart';
import 'developer_contact_screen.dart';
import 'webdav_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function()? onClearMapCache;
  const SettingsScreen({super.key, this.onClearMapCache});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有收藏？'),
        content: const Text('此操作无法恢复。'),
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
    if (confirmed != true || !mounted) return;
    final ok = await context.read<CollectionProvider>().deleteAll();
    if (mounted) _message(ok ? '已清除' : '清除失败');
  }

  Future<void> _notifications(bool enabled) async {
    setState(() => _busy = true);
    try {
      if (enabled && !await NearbyNotifications.instance.enable()) {
        if (mounted) _message('请开启通知和定位权限');
        return;
      }
      if (!mounted) return;
      final ok = await context.read<CollectionProvider>().setPreference(
        'nearby_reminders',
        enabled ? '1' : '0',
      );
      if (mounted && !ok) _message('保存失败');
    } catch (_) {
      if (mounted) _message('暂时无法开启提醒');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _version() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      showAboutDialog(
        context: context,
        applicationName: '拾途',
        applicationVersion: '${info.version} (${info.buildNumber})',
      );
    }
  }

  Future<void> _feedback() async {
    final info = await PackageInfo.fromPlatform();
    await launchUrl(
      Uri.https('github.com', '/Coveduoji/tastemap/issues/new', {
        'title': '使用反馈',
        'body': '版本：${info.version}\n\n问题描述：\n',
      }),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _clearMapCache() async {
    try {
      await widget.onClearMapCache?.call();
      PaintingBinding.instance.imageCache.clear();
      if (mounted) _message('已清理');
    } catch (_) {
      if (mounted) _message('清理失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _group([
            _item(
              Icons.cloud_sync_outlined,
              '坚果云同步',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebDavScreen()),
              ),
            ),
            _item(
              Icons.file_download_outlined,
              '导入数据',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ),
            ),
            _item(
              Icons.file_upload_outlined,
              '导出数据',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              ),
            ),
          ]),
          _group([
            _item(
              Icons.apps_rounded,
              '应用图标',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppIconScreen()),
              ),
            ),
          ]),
          _group([
            _item(Icons.cleaning_services_outlined, '清理地图缓存', _clearMapCache),
            SwitchListTile(
              title: const Text('附近收藏提醒'),
              subtitle: const Text('使用应用时'),
              secondary: const Icon(Icons.notifications_outlined),
              value: provider.nearbyReminders,
              onChanged: _busy ? null : _notifications,
            ),
            if (provider.nearbyReminders)
              _item(
                Icons.notifications_active_outlined,
                '测试提醒',
                () => NearbyNotifications.instance.test(),
              ),
          ]),
          _group([
            _item(Icons.info_outline, '版本信息', _version),
            _item(
              Icons.mail_outline,
              '联系开发者',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeveloperContactScreen(),
                ),
              ),
            ),
            _item(Icons.feedback_outlined, '反馈问题', _feedback),
            _item(
              Icons.help_outline,
              '使用说明',
              () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('使用说明'),
                  content: const Text(
                    '长按地图添加地点。\n搜索地点后查看详情，再收藏。\n缩小地图按国家、省、市、区查看收藏。\n下拉关闭面板。',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('完成'),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          _group([
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text(
                '清除所有收藏',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: _clearAll,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: children),
  );
  Widget _item(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right, size: 18),
    onTap: onTap,
  );
}
