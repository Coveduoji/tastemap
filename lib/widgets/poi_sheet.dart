import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../data/poi_search.dart';
import '../models/collection.dart';
import '../models/place.dart';
import '../models/nearby_category.dart';
import '../models/primary_tag.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/uuid.dart';
import 'collection_form_fields.dart';
import 'sheet_chrome.dart';

typedef NearbyPoiSearch =
    Future<List<Poi>> Function(
      double latitude,
      double longitude, {
      int limit,
      String? types,
      int radius,
    });

class PoiSheet extends StatefulWidget {
  final NearbyPoiSearch nearbySearch;
  final LatLng center;
  final ScrollController scrollController;
  final VoidCallback? onSaved;
  final ValueChanged<Poi>? onDetails;
  final bool startManual;
  final Poi? initialPoi;
  const PoiSheet({
    super.key,
    required this.center,
    required this.scrollController,
    this.onSaved,
    this.onDetails,
    this.startManual = false,
    this.initialPoi,
    this.nearbySearch = PoiSearchService.searchNearby,
  });
  @override
  State<PoiSheet> createState() => PoiSheetState();
}

class PoiSheetState extends State<PoiSheet> {
  final _formKey = GlobalKey<CollectionFormFieldsState>();
  final _name = TextEditingController();
  Poi? _poi;
  PlaceGeography? _geo;
  bool _form = false, _loading = true, _saving = false;
  Object? _error;
  List<Poi> _nearby = [];
  String? _nearbyTypes;
  int _nearbyRequest = 0;
  Future<void>? _geography;
  @override
  void initState() {
    super.initState();
    _poi = widget.initialPoi;
    _form = widget.startManual || _poi != null;
    if (_poi != null && _poi!.typeCode.isEmpty) {
      _loadInitialDetails();
    } else if (_form) {
      _loading = false;
    }
    if (_form) {
      _geography = _loadGeography();
    } else {
      _loadNearby();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadInitialDetails() async {
    try {
      final poi = await PoiSearchService.details(_poi!);
      if (mounted) setState(() => _poi = poi);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadGeography() async {
    try {
      final geo = await PoiSearchService.reverseGeocode(
        _poi?.latitude ?? widget.center.latitude,
        _poi?.longitude ?? widget.center.longitude,
      );
      if (mounted) setState(() => _geo = geo);
    } catch (_) {}
  }

  Future<void> _loadNearby() async {
    final request = ++_nearbyRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await widget.nearbySearch(
        widget.center.latitude,
        widget.center.longitude,
        types: _nearbyTypes,
        radius: 3000,
        limit: 25,
      );
      if (mounted && request == _nearbyRequest) {
        setState(() => _nearby = values);
      }
    } catch (e) {
      if (mounted && request == _nearbyRequest) setState(() => _error = e);
    } finally {
      if (mounted && request == _nearbyRequest) {
        setState(() => _loading = false);
      }
    }
  }

  void _setCategory(String? code) {
    if (_nearbyTypes == code) return;
    setState(() => _nearbyTypes = code);
    _loadNearby();
  }

  Future<void> _chooseCategory() async {
    final result = await showModalBottomSheet<({String? code})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in nearbyCategories)
                ChoiceChip(
                  label: Text(category.label),
                  selected: category.code == _nearbyTypes,
                  onSelected: (_) =>
                      Navigator.pop(context, (code: category.code)),
                ),
            ],
          ),
        ),
      ),
    );
    if (mounted && result != null) _setCategory(result.code);
  }

  void _select(Poi poi) {
    setState(() {
      _poi = poi;
      _form = true;
      _loading = false;
    });
    _geography = _loadGeography();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || _saving) return;
    final name = _poi?.name ?? _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('填写地点名称')));
      return;
    }
    setState(() => _saving = true);
    await _geography;
    if (!mounted) return;
    final now = nowIso8601();
    String? value(String? primary, String? fallback) =>
        primary?.isNotEmpty == true ? primary : fallback;
    final place = Place(
      id: generateId(),
      name: name,
      latitude: _poi?.latitude ?? widget.center.latitude,
      longitude: _poi?.longitude ?? widget.center.longitude,
      province: value(_poi?.province, _geo?.province),
      city: value(_poi?.city, _geo?.city),
      district: value(_poi?.district, _geo?.district),
      country: _geo?.country,
      adcode: value(_poi?.adcode, _geo?.adcode),
      amapId: _poi?.id.isNotEmpty == true ? _poi!.id : null,
      address: value(_poi?.addr, _geo?.address),
      type: _poi == null ? 'custom' : 'poi',
      source: _poi == null ? 'local' : 'amap',
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
    setState(() => _saving = false);
    if (ok) {
      widget.onSaved?.call();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未能收藏，请重试')));
    }
  }

  @override
  Widget build(BuildContext context) =>
      SheetContainer(child: _form ? _buildForm() : _buildNearby());
  Widget _buildNearby() => ListView(
    controller: widget.scrollController,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      Text('附近', style: AppText.sectionTitle),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in nearbyCategories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.label),
                        selected: _nearbyTypes == category.code,
                        onSelected: (_) => _setCategory(category.code),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: '全部分类',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _chooseCategory,
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_loading)
        const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_error != null)
        TextButton(onPressed: _loadNearby, child: const Text('重试'))
      else if (_nearby.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Text('附近暂无地点'))
      else
        ..._nearby.map(
          (poi) => ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: Icon(poi.category.icon, color: poi.category.color),
            title: Text(poi.name),
            subtitle: Text(poi.addr, maxLines: 2),
            trailing: Text(poi.distance, style: AppText.caption),
            onTap: () => _select(poi),
          ),
        ),
      TextButton.icon(
        onPressed: () {
          setState(() {
            _form = true;
            _poi = null;
            _loading = false;
          });
          _geography = _loadGeography();
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('添加地点'),
      ),
    ],
  );
  Widget _buildForm() {
    if (_loading) {
      return ListView(
        controller: widget.scrollController,
        children: const [
          SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    final address = _poi?.addr.isNotEmpty == true ? _poi!.addr : _geo?.address;
    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        if (_poi == null)
          TextField(
            controller: _name,
            autofocus: true,
            style: AppText.placeName,
            decoration: const InputDecoration(hintText: '给这个地点起个名字…'),
          )
        else
          InkWell(
            onTap: () => widget.onDetails?.call(_poi!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(_poi!.name, style: AppText.placeName)),
                  const Icon(Icons.chevron_right, color: AppColors.stone),
                ],
              ),
            ),
          ),
        if (address?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(address!, style: AppText.caption),
          ),
        const SizedBox(height: 24),
        CollectionFormFields(
          key: _formKey,
          initialTag: _poi?.category.suggestedTag ?? PrimaryTag.other,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '收藏中…' : '收藏'),
        ),
      ],
    );
  }
}
