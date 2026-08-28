import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/collection_repository.dart';
import '../data/sync_service.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// 坚果云 WebDAV 同步配置页：地址/账号/密码 + 手动备份/恢复。
class WebDavScreen extends StatefulWidget {
  const WebDavScreen({super.key});

  @override
  State<WebDavScreen> createState() => _WebDavScreenState();
}

class _WebDavScreenState extends State<WebDavScreen> {
  final _repo = CollectionRepository();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    _urlController.text = await _repo.getSetting('webdav_url') ?? '';
    _userController.text = await _repo.getSetting('webdav_username') ?? '';
    _passController.text = await _repo.getSetting('webdav_password') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _saveConfig() async {
    await _repo.setSetting('webdav_url', _urlController.text.trim());
    await _repo.setSetting('webdav_username', _userController.text.trim());
    await _repo.setSetting('webdav_password', _passController.text);
  }

  SyncService _service() => SyncService(
        url: _urlController.text.trim(),
        username: _userController.text.trim(),
        password: _passController.text,
      );

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _backup() async {
    await _saveConfig();
    setState(() => _busy = true);
    try {
      final places = await _repo.getAllPlaces();
      final views = await _repo.getCollectionViews();
      final collections = views.map((v) => v.collection).toList();
      final json = _service().buildBackupJson(places, collections);
      final ok = await _service().upload(json);
      if (mounted) _toast(ok ? '✓ 备份成功' : '备份失败，请检查配置');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final provider = context.read<CollectionProvider>();
    await _saveConfig();
    setState(() => _busy = true);
    try {
      final json = await _service().download();
      if (json == null) {
        if (mounted) _toast('下载失败，请检查配置');
        return;
      }
      final parsed = _service().parseBackupJson(json);
      final ok = await provider.importAll(parsed.places, parsed.collections);
      if (mounted) _toast(ok ? '✓ 恢复成功' : '恢复失败');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  Text('坚果云同步',
                      style: AppText.sectionTitle.copyWith(fontSize: 16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text('WebDAV 地址', style: AppText.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: _dec('https://dav.jianguoyun.com/dav/'),
                  ),
                  const SizedBox(height: 14),
                  Text('账号', style: AppText.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _userController,
                    decoration: _dec('坚果云账号'),
                  ),
                  const SizedBox(height: 14),
                  Text('应用密码', style: AppText.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: _dec('坚果云生成的第三方应用密码'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '提示：登录坚果云 → 账户信息 → 安全选项 → 第三方应用管理 → 生成应用密码',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 24),
                  _actionButton('立即备份到云端', _backup),
                  const SizedBox(height: 10),
                  _actionButton('从云端恢复', _restore, secondary: true),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
      );

  Widget _actionButton(String label, VoidCallback onTap,
      {bool secondary = false}) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: secondary ? AppColors.bg : AppColors.ink,
          borderRadius: BorderRadius.circular(13),
        ),
        child: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.warmWhite),
              )
            : Text(
                label,
                style: AppText.chip.copyWith(
                  color: secondary ? AppColors.ink : AppColors.warmWhite,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
