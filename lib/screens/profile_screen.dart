import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collection_view.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/format.dart';
import '../widgets/detail_sheet.dart';
import 'collection_list_screen.dart';
import 'settings_screen.dart';

/// Profile 页（头像点击进入）：Hero 卡 + 收藏统计 + 收藏格 + 城市足迹。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final all = provider.all;
    final cities = all.map((v) => v.city).whereType<String>().toSet();
    final countries = all.map((v) => v.country).whereType<String>().toSet();

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE8),
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
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 2,
                    child: ColoredBox(color: AppColors.ink),
                  ),
                  SizedBox(height: 4),
                  SizedBox(
                    width: 14,
                    height: 2,
                    child: ColoredBox(color: AppColors.ink),
                  ),
                  SizedBox(height: 4),
                  SizedBox(
                    width: 20,
                    height: 2,
                    child: ColoredBox(color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, int total, int cityCount, int countryCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F0F8), Color(0xFFD4E4F4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC4A882), Color(0xFF8B6A44)],
                  ),
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('🐕', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('旅行者', style: AppText.profileNick),
                    const SizedBox(height: 3),
                    Text('个人品味地图', style: AppText.caption.copyWith(color: const Color(0xFF6B7A8A))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _stat('$total', '收藏'),
                        const SizedBox(width: 16),
                        _stat('$cityCount', '城市'),
                        const SizedBox(width: 16),
                        _stat('$countryCount', '国家'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE8EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '✓ $total 个收藏分布在地图上',
                    style: AppText.caption.copyWith(color: const Color(0xFF6B7A8A)),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Text('去地图看看 →',
                          style: AppText.chip.copyWith(color: AppColors.warmWhite, fontSize: 10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String num, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(num, style: AppText.sectionTitle.copyWith(fontSize: 17)),
        const SizedBox(height: 1),
        Text(label, style: AppText.caption.copyWith(color: const Color(0xFF6B7A8A), fontSize: 9)),
      ],
    );
  }

  Widget _collectionsSection(BuildContext context, List<CollectionView> all) {
    final recent = all.take(5).toList();
    final remaining = all.length - recent.length;

    return _sectionCard(
      title: '我的收藏',
      count: all.length,
      onMore: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CollectionListScreen()),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
        children: [
          ...recent.map((v) => _collectionTile(context, v)),
          if (remaining > 0) _moreTile(remaining),
        ],
      ),
    );
  }

  Widget _collectionTile(BuildContext context, CollectionView v) {
    return GestureDetector(
      onTap: () => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DetailSheet(view: v),
      ),
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: v.tag.bubbleColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(v.tag.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    v.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 7, color: AppColors.ink),
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

  Widget _moreTile(int remaining) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFC5C0B8), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('+$remaining', style: AppText.sectionTitle.copyWith(color: AppColors.stone)),
          Text('更多', style: AppText.caption.copyWith(fontSize: 7)),
        ],
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
        children: rows.map((e) => _cityRow(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _cityRow(String city, List<CollectionView> views) {
    final country = views.map((v) => v.country).whereType<String>().firstOrNull;
    final earliest = views
        .map((v) => v.createdAt)
        .where((s) => s.isNotEmpty)
        .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    final dateText = earliest.isEmpty ? '' : formatYearMonth(earliest);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE6),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(_flagFor(country), style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city, style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
                Text(
                  [country, dateText].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Text('${views.length} 个',
              style: AppText.chip.copyWith(color: AppColors.terracotta)),
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
    VoidCallback? onMore,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 11, 14, 0),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppText.sectionTitle),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text('· $count', style: AppText.caption),
              ],
              const Spacer(),
              if (onMore != null)
                GestureDetector(
                  onTap: onMore,
                  child: Text('查看全部 ›',
                      style: AppText.chip
                          .copyWith(color: AppColors.terracotta, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}
