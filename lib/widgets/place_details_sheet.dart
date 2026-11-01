import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/poi_search.dart';
import '../models/collection.dart';
import '../models/collection_view.dart';
import '../models/place.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import 'edit_collection_sheet.dart';
import 'nav_picker.dart';
import 'photo_viewer.dart';

/// Content for Flutter's persistent draggable sheet; MapScreen owns the map below.
class PlaceDetailsSheet extends StatefulWidget {
  final Poi place;
  final ScrollController scrollController;
  final Future<void> Function(Poi) onCollect;
  final ValueChanged<Poi> onPlaceSelected;
  const PlaceDetailsSheet({
    super.key,
    required this.place,
    required this.scrollController,
    required this.onCollect,
    required this.onPlaceSelected,
  });
  @override
  State<PlaceDetailsSheet> createState() => _PlaceDetailsSheetState();
}

class _PlaceDetailsSheetState extends State<PlaceDetailsSheet> {
  late Poi _place;
  bool _loading = true;
  List<Poi> _transport = [];
  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _load();
    _loadTransport();
  }

  Future<void> _load() async {
    try {
      final place = await PoiSearchService.details(widget.place);
      if (mounted) setState(() => _place = place);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTransport() async {
    try {
      final values = await PoiSearchService.searchNearby(
        _place.latitude,
        _place.longitude,
        types: '150500|150700|150900',
        radius: 1200,
        limit: 5,
      );
      if (mounted) {
        setState(
          () => _transport = values.where((p) => p.id != _place.id).toList(),
        );
      }
    } catch (_) {
      /* Supplementary transport must not block basic details. */
    }
  }

  CollectionView? _saved(CollectionProvider provider) => provider.all
      .where(
        (v) =>
            (_place.id.isNotEmpty && v.place.amapId == _place.id) ||
            (v.name == widget.place.name &&
                const Distance().as(
                      LengthUnit.Meter,
                      LatLng(v.latitude, v.longitude),
                      LatLng(_place.latitude, _place.longitude),
                    ) <
                    80),
      )
      .firstOrNull;
  CollectionView _navigationView(Poi place) => CollectionView(
    place: Place(
      id: 'preview',
      name: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.addr,
      city: place.city,
      createdAt: '',
    ),
    collection: Collection(
      id: 'preview',
      placeId: 'preview',
      primaryTag: place.category.suggestedTag,
      createdAt: '',
      updatedAt: '',
    ),
  );
  Future<void> _navigate(Poi poi) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => NavPickerSheet(view: _navigationView(poi)),
  );
  Future<void> _external(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* A missing target app should leave the sheet usable. */
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂时无法打开')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved(context.watch<CollectionProvider>());
    final region = [
      _place.province,
      _place.city,
      _place.district,
    ].where((s) => s.isNotEmpty).toSet().join(' · ');
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
            children: [
              SizedBox(
                height: 30,
                child: Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.stone.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Text(
                _place.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (_place.alias.isNotEmpty && _place.alias != _place.name)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _place.alias,
                    style: const TextStyle(color: AppColors.stone),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: Icon(
                      saved?.tag.icon ?? _place.category.icon,
                      size: 16,
                    ),
                    label: Text(
                      saved?.tag.label ??
                          (_place.typeDescription.isEmpty
                              ? _place.category.label
                              : _place.typeDescription.split(';').last),
                    ),
                  ),
                  if (saved != null)
                    ...saved.secondaryTags.map((tag) => Chip(label: Text(tag))),
                  if (_place.rating.isNotEmpty)
                    Chip(
                      avatar: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 17,
                      ),
                      label: Text(_place.rating),
                    ),
                  if (_place.cost.isNotEmpty && _place.cost != '0')
                    Chip(label: Text('人均 ¥${_place.cost}')),
                ],
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              if (_place.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _place.photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => showPhotoViewer(
                          context,
                          images: _place.photos
                              .map(CachedNetworkImageProvider.new)
                              .toList(),
                          initialIndex: i,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CachedNetworkImage(
                            imageUrl: _place.photos[i],
                            width: 220,
                            height: 160,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.bg,
                              width: 220,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.stone,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_place.addr.isNotEmpty)
                _row(Icons.location_on_outlined, _place.addr),
              if (region.isNotEmpty) _row(Icons.map_outlined, region),
              if (_place.hours.isNotEmpty) _row(Icons.schedule, _place.hours),
              if (_place.weeklyHours.isNotEmpty &&
                  _place.weeklyHours != _place.hours)
                _row(Icons.date_range_outlined, _place.weeklyHours),
              if (_place.businessArea.isNotEmpty)
                _row(Icons.storefront_outlined, _place.businessArea),
              if (_place.feature.isNotEmpty)
                _row(Icons.local_offer_outlined, _place.feature),
              if (_place.floor.isNotEmpty)
                _row(Icons.layers_outlined, '${_place.floor} 层'),
              if (_place.parkingType.isNotEmpty)
                _row(Icons.local_parking_outlined, _place.parkingType),
              if (_place.phone.isNotEmpty)
                InkWell(
                  onTap: () => _external(
                    Uri(
                      scheme: 'tel',
                      path: _place.phone.split(RegExp(r'[;,、]')).first,
                    ),
                  ),
                  child: _row(Icons.call_outlined, _place.phone),
                ),
              if (saved?.note.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    saved!.note,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
              if (saved?.images.isNotEmpty == true)
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: saved!.images
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () => showPhotoViewer(
                                context,
                                images: saved.images
                                    .map((path) => FileImage(File(path)))
                                    .toList(),
                                initialIndex: entry.key,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(entry.value),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.image_outlined),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (_place.children.isNotEmpty) ...[
                _heading('这里还有'),
                ..._place.children
                    .take(8)
                    .map(
                      (poi) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          poi.category.icon,
                          color: AppColors.stone,
                        ),
                        title: Text(poi.name),
                        subtitle: poi.addr.isEmpty ? null : Text(poi.addr),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onPlaceSelected(poi),
                      ),
                    ),
              ],
              if (_transport.isNotEmpty) ...[
                _heading('周边交通'),
                ..._transport.map(
                  (poi) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      poi.typeCode.startsWith('1509')
                          ? Icons.local_parking_outlined
                          : Icons.directions_transit_outlined,
                      color: AppColors.stone,
                    ),
                    title: Text(poi.name),
                    subtitle: Text(
                      [
                        poi.distance,
                        poi.addr,
                      ].where((s) => s.isNotEmpty).join(' · '),
                    ),
                    trailing: IconButton(
                      tooltip: '导航',
                      onPressed: () => _navigate(poi),
                      icon: const Icon(Icons.navigation_outlined),
                    ),
                    onTap: () => widget.onPlaceSelected(poi),
                  ),
                ),
              ],
              TextButton.icon(
                onPressed: () => _external(
                  _place.id.isEmpty
                      ? Uri.https('uri.amap.com', '/marker', {
                          'position': '${_place.longitude},${_place.latitude}',
                          'name': _place.name,
                          'coordinate': 'gaode',
                          'callnative': '1',
                        })
                      : Uri.https('www.amap.com', '/place/${_place.id}'),
                ),
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text('高德地图'),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _navigate(_place),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('导航'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (saved == null) {
                        await widget.onCollect(_place);
                      } else {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => EditCollectionSheet(view: saved),
                        );
                      }
                    },
                    icon: Icon(
                      saved == null
                          ? Icons.bookmark_add_outlined
                          : Icons.edit_outlined,
                    ),
                    label: Text(saved == null ? '收藏' : '编辑收藏'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    ),
  );
  Widget _row(IconData icon, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: AppColors.stone),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 15, height: 1.5)),
        ),
      ],
    ),
  );
}
