import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collection_view.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/detail_sheet.dart';

/// 城市视图：收藏列表按城市分组折叠显示（PRD §5.2）。
class CollectionListScreen extends StatelessWidget {
  const CollectionListScreen({super.key});

  Map<String, List<CollectionView>> _groupByCity(List<CollectionView> all) {
    final map = <String, List<CollectionView>>{};
    for (final v in all) {
      final key = v.city ?? '未知城市';
      map.putIfAbsent(key, () => []).add(v);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<CollectionProvider>().all;
    final grouped = _groupByCity(all);

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                  ),
                  const SizedBox(width: 6),
                  Text('我的收藏', style: AppText.sectionTitle.copyWith(fontSize: 16)),
                ],
              ),
            ),
            Expanded(
              child: all.isEmpty
                  ? Center(
                      child: Text('还没有收藏', style: AppText.caption),
                    )
                  : ListView(
                      children: grouped.entries
                          .map((e) => _cityGroup(context, e.key, e.value))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cityGroup(
      BuildContext context, String city, List<CollectionView> views) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          title: Row(
            children: [
              Text(
                city,
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text('${views.length} 个',
                  style: AppText.chip.copyWith(color: AppColors.terracotta)),
            ],
          ),
          children: views.map((v) => _tile(context, v)).toList(),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, CollectionView v) {
    return InkWell(
      onTap: () => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DetailSheet(view: v),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: v.tag.bubbleColor,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(v.tag.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v.tag.label + (v.visited ? ' · 已打卡' : ' · 待打卡'),
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            if (v.secondaryTags.isNotEmpty)
              Text(
                v.secondaryTags.first,
                style: AppText.caption.copyWith(color: AppColors.stone),
              ),
          ],
        ),
      ),
    );
  }
}
