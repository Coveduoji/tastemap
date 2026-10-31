import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../theme/colors.dart';

class DeveloperContactScreen extends StatefulWidget {
  const DeveloperContactScreen({super.key});

  static const email = 'miston.wei@qq.com';
  static const wechatAsset = 'assets/contact/wechat.png';

  @override
  State<DeveloperContactScreen> createState() => _DeveloperContactScreenState();
}

class _DeveloperContactScreenState extends State<DeveloperContactScreen> {
  bool _hasWechat = false;

  @override
  void initState() {
    super.initState();
    _loadWechat();
  }

  Future<void> _loadWechat() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    if (mounted) {
      setState(
        () => _hasWechat = manifest.listAssets().contains(
          DeveloperContactScreen.wechatAsset,
        ),
      );
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(
      const ClipboardData(text: DeveloperContactScreen.email),
    );
    if (mounted) _message('邮箱已复制');
  }

  Future<void> _email() async {
    try {
      final opened = await launchUrl(
        Uri(
          scheme: 'mailto',
          path: DeveloperContactScreen.email,
          queryParameters: {'subject': '拾途反馈'},
        ),
      );
      if (!opened && mounted) await _copyEmail();
    } catch (_) {
      if (mounted) await _copyEmail();
    }
  }

  Future<void> _github() async {
    try {
      if (!await launchUrl(
            Uri.parse('https://github.com/Coveduoji/tastemap/issues'),
            mode: LaunchMode.externalApplication,
          ) &&
          mounted) {
        _message('暂时无法打开');
      }
    } catch (_) {
      if (mounted) _message('暂时无法打开');
    }
  }

  Future<void> _shareWechat(BuildContext buttonContext) async {
    try {
      final bytes = await rootBundle.load(DeveloperContactScreen.wechatAsset);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/shitu-developer-wechat.png');
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      if (!buttonContext.mounted) return;
      final box = buttonContext.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) _message('暂时无法分享');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('联系开发者')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('邮箱'),
            subtitle: const Text(DeveloperContactScreen.email),
            onTap: _email,
            trailing: IconButton(
              tooltip: '复制邮箱',
              icon: const Icon(Icons.copy_outlined),
              onPressed: _copyEmail,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.forum_outlined),
            title: const Text('GitHub'),
            subtitle: const Text('问题反馈与建议'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: _github,
          ),
        ),
        if (_hasWechat) ...[
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    '微信',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  InteractiveViewer(
                    maxScale: 3,
                    child: Image.asset(
                      DeveloperContactScreen.wechatAsset,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) => TextButton.icon(
                      onPressed: () => _shareWechat(context),
                      icon: const Icon(
                        Icons.ios_share,
                        color: AppColors.accent,
                      ),
                      label: const Text('分享二维码'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
