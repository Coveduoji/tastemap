import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../data/poi_search.dart';
import '../models/collection.dart';
import '../models/place.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/uuid.dart';
import 'collection_form_fields.dart';
import 'sheet_chrome.dart';

/// 收藏流程 Sheet：Step 1 附近地点列表 → Step 2 填写表单（共享同一容器，DDR-03）。
class PoiSheet extends StatefulWidget {
  final LatLng center;
  final ScrollController scrollController;
  final void Function(double lat, double lng)? onSelectLocation;
  final VoidCallback? onClose;
  final VoidCallback? onSaved;
  /// 长按「+」打开时为 true：跳过附近地点列表，直接进入第 2 步表单内联填写名称（自定义地点，如秋千/拍照机位）。
  final bool startManual;

  const PoiSheet({
    super.key,
    required this.center,
    required this.scrollController,
    this.onSelectLocation,
    this.onClose,
    this.onSaved,
    this.startManual = false,
  });

  @override
  State<PoiSheet> createState() => PoiSheetState();
}

class PoiSheetState extends State<PoiSheet> {
  int _step = 0; // 0 = 列表，1 = 填写
  String _name = '';
  String _addr = '';
  String _city = '';
  String _country = '';
  double _lat = 0;
  double _lng = 0;
  bool _isCustom = false; // true = 自定义地点(长按/手动输入)，第 2 步名称可编辑
  late LatLng _currentCenter;
  final _formKey = GlobalKey<CollectionFormFieldsState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  List<Poi> _pois = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.center;
    _loadPois();
    if (widget.startManual) {
      // 附近地点列表在背后加载，供用户改主意时点「← 重新选择」切回
      WidgetsBinding.instance.addPostFrameCallback((_) => _manualInput());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPois() async {
    final result = await PoiSearchService.searchNearby(
      _currentCenter.latitude,
      _currentCenter.longitude,
    );
    if (mounted) {
      setState(() {
        _pois = result;
        _loading = false;
      });
    }
  }

  /// 地图被拖动后，以新中心重新搜索附近地点（仅列表步骤生效）。
  Future<void> reloadNearby(LatLng center) async {
    if (_step != 0) return;
    _currentCenter = center;
    final result =
        await PoiSearchService.searchNearby(center.latitude, center.longitude);
    if (mounted) {
      setState(() {
        _pois = result;
        _loading = false;
      });
    }
  }

  Future<void> _onSearch(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) {
      _loadPois(); // 清空关键词 → 回到附近地点
      return;
    }
    setState(() => _loading = true);
    final result = await PoiSearchService.searchByName(
      kw,
      _currentCenter.latitude,
      _currentCenter.longitude,
    );
    if (mounted) {
      setState(() {
        _pois = result;
        _loading = false;
      });
    }
  }

  Future<void> _select(Poi poi) async {
    // 通知地图移动到选中地点
    widget.onSelectLocation?.call(poi.latitude, poi.longitude);
    final geo = await PoiSearchService.reverseGeocode(poi.latitude, poi.longitude);
    if (!mounted) return;
    setState(() {
      _name = poi.name;
      _addr = poi.addr;
      _city = poi.city.isNotEmpty ? poi.city : (geo.city ?? '');
      _country = geo.country ?? '';
      _lat = poi.latitude;
      _lng = poi.longitude;
      _isCustom = false;
      _step = 1;
    });
  }

  /// 供长按「+」时从外部触发：跳过列表，直接对当前钉子位置命名(自定义地点)。
  Future<void> startManualEntry() => _manualInput();

  /// 自定义地点：地图上没有对应 POI 的位置(如秋千、拍照机位)。
  /// 不用弹窗打字，直接进第 2 步表单内联编辑名称，跟其余表单字段一致的体验。
  Future<void> _manualInput() async {
    _nameController.clear();
    final geo = await PoiSearchService.reverseGeocode(
        _currentCenter.latitude, _currentCenter.longitude);
    if (!mounted) return;
    setState(() {
      _addr = '自定义地点';
      _city = geo.city ?? '';
      _country = geo.country ?? '';
      _lat = _currentCenter.latitude;
      _lng = _currentCenter.longitude;
      _isCustom = true;
      _step = 1;
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;
    final name = _isCustom ? _nameController.text.trim() : _name;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先给这个地点起个名字')),
      );
      return;
    }
    final now = nowIso8601();
    final place = Place(
      id: generateId(),
      name: name,
      latitude: _lat,
      longitude: _lng,
      city: _city.isEmpty ? null : _city,
      country: _country.isEmpty ? null : _country,
      type: 'custom',
      createdAt: now,
    );
    final collection = Collection(
      id: generateId(),
      placeId: place.id,
      primaryTag: form.tag,
      secondaryTags: form.secondaryTags,
      note: form.note,
      images: form.images,
      visitedStatus: form.visited ? 'visited' : 'pending',
      createdAt: now,
      updatedAt: now,
    );
    final ok = await context.read<CollectionProvider>().save(place, collection);
    if (!mounted) return;
    if (ok) {
      widget.onSaved?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请检查存储空间后重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      child: _step == 0 ? _buildList() : _buildForm(),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        const SheetHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('附近地点', style: AppText.sectionTitle),
                        const SizedBox(height: 3),
                        Text('选择你想收藏的地点 · 按距离排序', style: AppText.caption),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onClose?.call(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Text('×',
                          style: TextStyle(fontSize: 20, color: AppColors.stone)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearch,
                decoration: InputDecoration(
                  hintText: '搜索地点名称...',
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.stone),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.bg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _pois.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('附近暂无搜索结果')),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: _pois.length,
                      itemBuilder: (_, i) => _PoiItem(
                        poi: _pois[i],
                        onTap: () => _select(_pois[i]),
                      ),
                    ),
        ),
        _ManualEntry(onTap: _manualInput),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _step = 0),
                      child: Text('← 重新选择',
                          style: AppText.chip.copyWith(color: AppColors.accent)),
                    ),
                    const Spacer(),
                    Text('第 2 步 · 共 2 步', style: AppText.caption),
                  ],
                ),
                const SizedBox(height: 12),
                _isCustom
                    ? TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: AppText.placeName,
                        decoration: const InputDecoration(
                          isDense: true,
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: '给这个地点起个名字…',
                        ),
                      )
                    : Text(_name, style: AppText.placeName),
                const SizedBox(height: 2),
                Text(_addr, style: AppText.caption),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 16),
                CollectionFormFields(key: _formKey),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _SaveButton(onTap: _save, label: '保存收藏'),
          ),
        ],
      ),
    );
  }
}

class _PoiItem extends StatelessWidget {
  final Poi poi;
  final VoidCallback onTap;

  const _PoiItem({required this.poi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: poi.tag.bubbleColor,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(poi.tag.icon, size: 20, color: AppColors.ink),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poi.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(poi.addr, style: AppText.caption),
                ],
              ),
            ),
            Text(
              poi.distance.isNotEmpty ? poi.distance : poi.city,
              style: AppText.chip.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _ManualEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add_location_alt, size: 19, color: AppColors.stone),
            ),
            const SizedBox(width: 11),
            Text('找不到？',
                style: AppText.body.copyWith(color: AppColors.stone)),
            const SizedBox(width: 4),
            Text('手动输入地点名称',
                style: AppText.chip.copyWith(color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _SaveButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(label,
            style: AppText.chip
                .copyWith(color: AppColors.warmWhite, fontSize: 14)),
      ),
    );
  }
}
