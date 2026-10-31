import 'package:flutter/material.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';

import '../theme/colors.dart';

class AppIconScreen extends StatefulWidget {
  const AppIconScreen({super.key});

  @override
  State<AppIconScreen> createState() => _AppIconScreenState();
}

class _AppIconScreenState extends State<AppIconScreen> {
  static const _options = [
    (alias: 'IconWander', label: '漫游', asset: 'wander'),
    (alias: 'IconJournal', label: '手账', asset: 'journal'),
  ];
  String? _selected;
  bool _loading = true;
  bool _saving = false;
  bool _supported = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
      final current = supported
          ? await FlutterDynamicIconPlus.alternateIconName
          : null;
      if (!mounted) return;
      setState(() {
        _error = null;
        _supported = supported;
        _selected = current?.split('.').last ?? 'IconWander';
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '暂时无法读取应用图标';
          _loading = false;
        });
      }
    }
  }

  Future<void> _select(String alias) async {
    if (_saving || alias == _selected) return;
    setState(() => _saving = true);
    try {
      await FlutterDynamicIconPlus.setAlternateIconName(
        iconName: alias,
        // The plugin's documented immediate mode avoids waiting for task removal
        // on vivo/iQOO launchers. MainActivity always remains enabled.
        blacklistBrands: const ['vivo', 'iQOO'],
      );
      final active = await FlutterDynamicIconPlus.alternateIconName;
      if (!mounted) return;
      setState(() => _selected = alias);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            active?.split('.').last == alias ? '已切换，返回桌面查看' : '关闭应用后更新图标',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('切换失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('应用图标')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: TextButton(onPressed: _load, child: Text(_error!)),
          )
        : !_supported
        ? const Center(child: Text('当前设备暂不支持切换图标'))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  for (final option in _options)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Semantics(
                          selected: _selected == option.alias,
                          button: true,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _saving
                                  ? null
                                  : () => _select(option.alias),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: ColoredBox(
                                        color: Colors.white,
                                        child: Image.asset(
                                          'assets/app_icons/${option.asset}.png',
                                          width: 96,
                                          height: 96,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      option.label,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Icon(
                                      _selected == option.alias
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked,
                                      color: _selected == option.alias
                                          ? AppColors.accent
                                          : AppColors.stone,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
  );
}
