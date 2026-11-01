import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/collection_view.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';

Future<CollectionView?> showCollectionList(BuildContext context) =>
    showModalBottomSheet<CollectionView>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.bg,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const _CollectionPanel(),
    );

class _CollectionPanel extends StatefulWidget {
  const _CollectionPanel();
  @override
  State<_CollectionPanel> createState() => _CollectionPanelState();
}

class _CollectionPanelState extends State<_CollectionPanel> {
  final _controller = DraggableScrollableController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _expandForSearch() {
    if (_controller.isAttached) {
      _controller.animateTo(
        .92,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    controller: _controller,
    initialChildSize: .64,
    minChildSize: .24,
    maxChildSize: .92,
    expand: false,
    shouldCloseOnMinExtent: true,
    snap: true,
    snapSizes: const [.64],
    snapAnimationDuration: const Duration(milliseconds: 200),
    builder: (context, scroll) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: CollectionListSheet(
        scrollController: scroll,
        onSearchFocus: _expandForSearch,
      ),
    ),
  );
}

class CollectionListSheet extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onSearchFocus;
  const CollectionListSheet({
    super.key,
    required this.scrollController,
    this.onSearchFocus,
  });
  @override
  State<CollectionListSheet> createState() => _CollectionListSheetState();
}

class _CollectionListSheetState extends State<CollectionListSheet> {
  final _collapsed = <String>{};
  final _deleting = <String>{};
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(CollectionView view) async {
    if (!_deleting.add(view.id)) return;
    final provider = context.read<CollectionProvider>();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('删除收藏'),
          content: Text('确认删除「${view.name}」？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '删除',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      setState(() {});
      final ok = await provider.delete(view.id);
      if (mounted && !ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      }
    } finally {
      _deleting.remove(view.id);
      if (mounted) setState(() {});
    }
  }

  bool _matches(CollectionView view) {
    final terms = _query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty);
    final text = [
      view.name,
      view.city,
      view.place.province,
      view.place.district,
      view.place.address,
      view.tag.label,
      ...view.secondaryTags,
      view.note,
    ].whereType<String>().join(' ').toLowerCase();
    return terms.every(text.contains);
  }

  @override
  Widget build(
    BuildContext context,
  ) => Selector<CollectionProvider, List<CollectionView>>(
    selector: (_, provider) => provider.all,
    builder: (context, all, _) {
      final cities = <String, List<CollectionView>>{};
      final filtered = _query.trim().isEmpty
          ? all
          : all.where(_matches).toList();
      for (final view in filtered) {
        cities.putIfAbsent(view.city ?? '未知城市', () => []).add(view);
      }
      return SlidableAutoCloseBehavior(
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '我的收藏',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverAppBar(
              primary: false,
              automaticallyImplyLeading: false,
              pinned: true,
              toolbarHeight: 64,
              titleSpacing: 20,
              backgroundColor: AppColors.bg,
              surfaceTintColor: Colors.transparent,
              title: TextField(
                controller: _search,
                onTap: widget.onSearchFocus,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: '搜索收藏',
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空搜索',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    all.isEmpty ? '还没有收藏' : '没有匹配的收藏',
                    style: const TextStyle(color: AppColors.stone),
                  ),
                ),
              ),
            for (final city in cities.entries)
              SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 22,
                      ),
                      title: Text(
                        city.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${city.value.length} 个'),
                      trailing: AnimatedRotation(
                        turns: _query.isEmpty && _collapsed.contains(city.key)
                            ? -.25
                            : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                      onTap: _query.isNotEmpty
                          ? null
                          : () => setState(() {
                              if (!_collapsed.add(city.key)) {
                                _collapsed.remove(city.key);
                              }
                            }),
                    ),
                  ),
                  if (_query.isNotEmpty || !_collapsed.contains(city.key))
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: DecoratedSliver(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        sliver: SliverList.builder(
                          itemCount: city.value.length,
                          itemBuilder: (_, index) {
                            final view = city.value[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: index == 0
                                    ? const Radius.circular(22)
                                    : Radius.zero,
                                bottom: index == city.value.length - 1
                                    ? const Radius.circular(22)
                                    : Radius.zero,
                              ),
                              child: Slidable(
                                key: ValueKey(view.id),
                                groupTag: 'collections',
                                enabled: !_deleting.contains(view.id),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  extentRatio:
                                      (88 /
                                              (MediaQuery.sizeOf(
                                                    context,
                                                  ).width -
                                                  32))
                                          .clamp(.05, .35),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) => _delete(view),
                                      backgroundColor: AppColors.danger,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete_outline,
                                      label: '删除',
                                    ),
                                  ],
                                ),
                                child: ColoredBox(
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: view.tag.bubbleColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        view.tag.icon,
                                        size: 20,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    title: Text(
                                      view.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${view.tag.label} · ${view.visited ? '已打卡' : '待打卡'}',
                                    ),
                                    trailing: const Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: AppColors.stone,
                                    ),
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      Navigator.pop(context, view);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 24,
              ),
            ),
          ],
        ),
      );
    },
  );
}
