import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collection_view.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/format.dart';
import '../widgets/collection_list_sheet.dart';
import 'settings_screen.dart';

/// Profile 页（头像点击进入）：Hero 卡 + 收藏统计 + 收藏格 + 城市足迹。
class ProfileScreen extends StatelessWidget {
  final Future<void> Function()? onClearMapCache;
  const ProfileScreen({super.key, this.onClearMapCache});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final all = provider.all;
    final cities = all.map((v) => v.city).whereType<String>().toSet();
    final countries = all.map((v) => v.country).whereType<String>().toSet();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _navBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _hero(context, all.length, cities.length, countries.length),
                    _collectionsSection(context, all),
                    _citiesSection(context, all),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: '设置',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SettingsScreen(onClearMapCache: onClearMapCache),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    int total,
    int cityCount,
    int countryCount,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  color: AppColors.accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('我的足迹', style: AppText.profileNick)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _stat('$total', '收藏地点')),
              Expanded(child: _stat('$cityCount', '探索城市')),
              Expanded(child: _stat('$countryCount', '到访国家')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String num, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          num,
          style: AppText.sectionTitle.copyWith(fontSize: 30, letterSpacing: -1),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppText.caption),
      ],
    );
  }

  Widget _collectionsSection(BuildContext context, List<CollectionView> all) {
    final recent = all.take(5).toList();
    final remaining = all.length - recent.length;

    return _sectionCard(
      title: '我的收藏',
      count: all.length,
      child: all.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '收藏一处喜欢的地方。',
                style: AppText.body.copyWith(color: AppColors.stone),
              ),
            )
          : GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: [
                ...recent.map((v) => _collectionTile(context, v)),
                if (remaining > 0) _moreTile(context, remaining),
              ],
            ),
    );
  }

  Future<void> _chooseCollection(BuildContext context) async {
    final selected = await showCollectionList(context);
    if (selected != null && context.mounted) Navigator.pop(context, selected);
  }

  Widget _collectionTile(BuildContext context, CollectionView v) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, v),
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: v.tag.bubbleColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(v.tag.icon, size: 20, color: AppColors.ink),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    v.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: v.visited ? AppColors.visited : AppColors.pending,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreTile(BuildContext context, int remaining) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _chooseCollection(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+$remaining',
                style: AppText.sectionTitle.copyWith(color: AppColors.stone),
              ),
              Text('更多', style: AppText.caption.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _citiesSection(BuildContext context, List<CollectionView> all) {
    final byCity = <String, List<CollectionView>>{};
    for (final v in all) {
      final key = v.city ?? '未知城市';
      byCity.putIfAbsent(key, () => []).add(v);
    }
    final rows = byCity.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return _sectionCard(
      title: '城市足迹',
      child: Column(
        children: rows.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '下一座城市，等你点亮',
                    style: AppText.body.copyWith(color: AppColors.stone),
                  ),
                ),
              ]
            : rows.map((e) => _cityRow(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _cityRow(String city, List<CollectionView> views) {
    final country = views.map((v) => v.country).whereType<String>().firstOrNull;
    final earliest = views
        .map((v) => v.createdAt)
        .where((s) => s.isNotEmpty)
        .fold<String>('', (a, b) => a.isEmpty || b.compareTo(a) < 0 ? b : a);
    final dateText = earliest.isEmpty ? '' : formatYearMonth(earliest);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              _flagFor(country),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  [
                    country,
                    dateText,
                  ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Text(
            '${views.length} 个',
            style: AppText.chip.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  String _flagFor(String? country) {
    if (country == null) return '🌏';
    if (country.contains('日本')) return '🗾';
    if (country.contains('中国')) return '🇨🇳';
    return '🌏';
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    int? count,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(title, style: AppText.sectionTitle),
              if (count != null) ...[Text('· $count', style: AppText.caption)],
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}
