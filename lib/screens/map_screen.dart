import 'dart:io';
import 'dart:async';
import 'package:amap_location_flutter/amap_location_flutter.dart';
import 'package:amap_location_flutter/amap_location_option.dart' as location;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../data/collection_repository.dart';
import '../data/poi_search.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../utils/administrative_clusters.dart';
import '../utils/format.dart';
import '../widgets/detail_sheet.dart';
import '../widgets/native_amap.dart';
import '../widgets/pin_marker.dart';
import '../widgets/poi_sheet.dart';
import '../widgets/collection_list_sheet.dart';
import '../models/collection_view.dart';
import '../widgets/place_details_sheet.dart';
import 'place_search.dart';
import 'profile_screen.dart';

const kDefaultCenter = LatLng(39.9092, 116.3974);
const kDefaultZoom = 16.0;

class MapScreen extends StatefulWidget {
  final Poi? initialPlace;
  const MapScreen({super.key, this.initialPlace});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _fallback = MapController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController? _detailSheet;
  Poi? _focusedPlace;
  CollectionView? _savedPlace;
  final _savedExtent = ValueNotifier<double>(0);
  bool _locationEnabled = false, _locating = false;
  int _interactionEpoch = 0;
  final _areaLabel = ValueNotifier<String>('地图');
  Timer? _areaTimer;
  Timer? _savedNoticeTimer;
  bool _savedNotice = false;
  LatLng? _lastAreaCenter;
  int _areaRequest = 0;
  NativeMapController? _nativeController;
  LatLng _center = kDefaultCenter;
  double _zoom = kDefaultZoom;
  bool _native = false,
      _fallbackReady = false,
      _tip = false,
      _collecting = false,
      _backfilled = false;
  String _signature = '';
  List<PlaceCluster> _markers = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  @override
  void dispose() {
    _areaTimer?.cancel();
    _savedNoticeTimer?.cancel();
    _areaLabel.dispose();
    _savedExtent.dispose();
    _fallback.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    final provider = context.read<CollectionProvider>();
    final tip = await provider.claimFirstMapTip();
    if (!mounted) return;
    setState(() => _tip = tip);
    if (widget.initialPlace != null) {
      _move(
        LatLng(widget.initialPlace!.latitude, widget.initialPlace!.longitude),
        16,
      );
    } else if (provider.all.isNotEmpty) {
      final place = provider.all.first;
      _areaLabel.value = formatMapArea(
        city: place.city,
        province: place.place.province,
        district: place.place.district,
        country: place.country,
      );
      _move(LatLng(place.latitude, place.longitude), kDefaultZoom);
    }
    if (Platform.isAndroid && AppConfig.amapAndroidApiKey.isNotEmpty) {
      final repo = CollectionRepository();
      var consent = await repo.getSetting('amap_native_consent') == '1';
      if (!mounted) return;
      if (!consent) {
        consent =
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('使用高德地图'),
                content: const Text('地图由高德提供，将联网加载地图和地点信息。定位仍需系统授权。'),
                actions: [
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://lbs.amap.com/pages/privacy/'),
                    ),
                    child: const Text('隐私政策'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('暂不使用'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('同意并使用'),
                  ),
                ],
              ),
            ) ??
            false;
        if (consent) await repo.setSetting('amap_native_consent', '1');
      }
      if (mounted && consent) setState(() => _native = true);
    }
    if (!mounted) return;
    if (widget.initialPlace != null) {
      await _details(widget.initialPlace!);
    } else {
      await _locate();
    }
  }

  void _locationMessage(
    String message, {
    bool appSettings = false,
    bool locationSettings = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: appSettings || locationSettings
            ? SnackBarAction(
                label: '设置',
                onPressed: () {
                  if (appSettings) {
                    Geolocator.openAppSettings();
                  } else {
                    Geolocator.openLocationSettings();
                  }
                },
              )
            : null,
      ),
    );
  }

  Future<LatLng> _requestAmapLocation() async {
    final client = AmapLocationFlutter();
    final result = Completer<LatLng>();
    final subscription = client.onLocationChanged().listen(
      (event) {
        if (result.isCompleted) return;
        final code = int.tryParse('${event['errorCode'] ?? 0}') ?? -1;
        if (code != 0) {
          result.completeError(StateError('定位服务暂不可用（$code）'));
          return;
        }
        final lat = double.tryParse('${event['latitude']}');
        final lng = double.tryParse('${event['longitude']}');
        if (lat == null ||
            lng == null ||
            !lat.isFinite ||
            !lng.isFinite ||
            lat.abs() > 90 ||
            lng.abs() > 180 ||
            (lat == 0 && lng == 0)) {
          result.completeError(StateError('未获取到有效位置'));
          return;
        }
        result.complete(LatLng(lat, lng));
      },
      onError: (Object error) {
        if (!result.isCompleted) result.completeError(error);
      },
    );
    try {
      // This is invoked only after the existing map consent and OS permission gate.
      AmapLocationFlutter.setApiKey(AppConfig.amapAndroidApiKey, '');
      client.setLocationOption(
        location.AMapLocationOption(
          onceLocation: true,
          needAddress: false,
          locationMode: location.AMapLocationMode.Hight_Accuracy,
        ),
      );
      client.startLocation();
      return await result.future.timeout(const Duration(seconds: 20));
    } finally {
      client.stopLocation();
      client.destroy();
      await subscription.cancel();
    }
  }

  Future<void> _locate({bool interactive = false}) async {
    if (_locating) return;
    final epoch = _interactionEpoch;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (interactive) _locationMessage('请开启系统定位', locationSettings: true);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.deniedForever) {
        if (interactive) _locationMessage('请允许位置访问', appSettings: true);
        return;
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (interactive) _locationMessage('尚未获得定位权限');
        return;
      }
      LatLng point;
      if (_native) {
        // Use the location plugin's result stream, independent of map-rendering callbacks.
        setState(() => _locationEnabled = true);
        point = await _requestAmapLocation();
      } else {
        // Explicitly use Android's system provider instead of an unavailable GMS fused provider.
        final position = await Geolocator.getCurrentPosition(
          locationSettings: Platform.isAndroid
              ? AndroidSettings(
                  forceLocationManager: true,
                  accuracy: LocationAccuracy.medium,
                  timeLimit: const Duration(seconds: 25),
                )
              : const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 25),
                ),
        );
        final converted = await PoiSearchService.convertGps(
          position.latitude,
          position.longitude,
        );
        if (converted == null) throw StateError('坐标转换失败');
        point = LatLng(converted.latitude, converted.longitude);
      }
      if (mounted &&
          epoch == _interactionEpoch &&
          _focusedPlace == null &&
          !_collecting) {
        _move(point, 16);
      }
    } on TimeoutException {
      if (interactive) _locationMessage('定位超时，请稍后重试');
    } on StateError catch (error) {
      if (interactive) _locationMessage(error.message.toString());
    } catch (_) {
      if (interactive) _locationMessage('定位失败，请检查网络与位置权限');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _queueArea(LatLng point) {
    if (_focusedPlace != null) return;
    _areaTimer?.cancel();
    final request = ++_areaRequest;
    if (_lastAreaCenter != null &&
        const Distance().as(LengthUnit.Meter, _lastAreaCenter!, point) < 200) {
      return;
    }
    _areaTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final area = await PoiSearchService.reverseGeocode(
          point.latitude,
          point.longitude,
        );
        if (!mounted || request != _areaRequest || _focusedPlace != null) {
          return;
        }
        final label = formatMapArea(
          city: area.city,
          province: area.province,
          district: area.district,
          country: area.country,
        );
        if (label != '地图') {
          _areaLabel.value = label;
          _lastAreaCenter = point;
        }
      } catch (_) {
        /* Keep the last known area when networking is unavailable. */
      }
    });
  }

  void _move(LatLng point, double zoom) {
    setState(() {
      _center = point;
      _zoom = zoom;
    });
    _queueArea(point);
    if (_native) {
      _nativeController?.move(point, zoom);
    } else if (_fallbackReady) {
      _fallback.move(point, zoom);
    }
  }

  void _camera(NativeMapCamera camera) {
    final previousLevel = AdministrativeClusters.level(_zoom);
    _center = camera.center;
    _zoom = camera.zoom;
    _queueArea(camera.center);
    if (mounted && previousLevel != AdministrativeClusters.level(_zoom)) {
      setState(() {});
    }
  }

  Future<void> _showCollection(CollectionView view) async {
    await _dismissDetails();
    if (!mounted) return;
    _interactionEpoch++;
    final area = formatMapArea(
      city: view.city,
      province: view.place.province,
      district: view.place.district,
      country: view.country,
    );
    if (area != '地图') {
      _areaLabel.value = area;
    }
    final provider = context.read<CollectionProvider>();
    if (provider.selectedTag != null && provider.selectedTag != view.tag) {
      provider.setTag(null);
    }
    setState(() {
      _savedPlace = view;
      _focusedPlace = Poi.fromPlace(view.place);
      _savedExtent.value = .48;
    });
    _move(LatLng(view.latitude, view.longitude), 17);
  }

  Future<void> _collections() async {
    final selected = await showCollectionList(context);
    if (selected != null && mounted) _showCollection(selected);
  }

  Future<void> _profile() async {
    final selected = await Navigator.push<CollectionView>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          onClearMapCache: () async {
            await _nativeController?.clearCache();
          },
        ),
      ),
    );
    if (selected != null && mounted) _showCollection(selected);
  }

  void _syncMarkers() {
    final controller = _nativeController;
    if (!_native || controller == null) return;
    final signature =
        '${_markers.map((g) => '${g.id}:${g.title}:${g.members.length}:${g.members.first.tag.name}:${g.members.first.visited}:${g.point.latitude}:${g.point.longitude}').join('|')}:focus:${_focusedPlace?.id}:${_focusedPlace?.latitude}:${_focusedPlace?.longitude}';
    if (signature == _signature) return;
    _signature = signature;
    final payload = _markers
        .map(
          (g) => <String, dynamic>{
            'id': g.id,
            'title': g.title,
            'lat': g.point.latitude,
            'lng': g.point.longitude,
            'cluster': !g.isPlace,
            'count': g.members.length,
            'label': g.isPlace,
            'icon': g.members.first.tag.icon.codePoint,
            'visited': g.members.first.visited,
          },
        )
        .toList();
    final focused = _focusedPlace;
    if (focused != null &&
        !payload.any(
          (marker) =>
              ((marker['lat'] as num) - focused.latitude).abs() < .00001 &&
              ((marker['lng'] as num) - focused.longitude).abs() < .00001,
        )) {
      payload.add({
        'id': 'detail:selected',
        'title': focused.name,
        'lat': focused.latitude,
        'lng': focused.longitude,
        'cluster': false,
        'count': 1,
        'icon': focused.category.icon.codePoint,
        'visited': true,
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.markers(payload);
    });
  }

  void _markerTap(String id) {
    final group = _markers.where((g) => g.id == id).firstOrNull;
    if (group == null) return;
    if (!group.isPlace) {
      _move(group.point, group.nextZoom);
      return;
    }
    _showCollection(group.members.first);
  }

  void _closeSavedPlace() {
    if (_savedPlace == null) return;
    setState(() {
      _savedPlace = null;
      _focusedPlace = null;
      _savedExtent.value = 0;
    });
    _queueArea(_center);
  }

  Future<void> _dismissDetails() async {
    _closeSavedPlace();
    final sheet = _detailSheet;
    if (sheet == null) return;
    sheet.close();
    await sheet.closed;
  }

  Future<void> _details(Poi poi) async {
    _interactionEpoch++;
    _areaTimer?.cancel();
    _areaRequest++;
    final area = formatMapArea(
      city: poi.city,
      province: poi.province,
      district: poi.district,
    );
    if (area != '地图') {
      _areaLabel.value = area;
    }
    await _dismissDetails();
    if (!mounted) return;
    setState(() {
      _focusedPlace = poi;
    });
    _move(LatLng(poi.latitude, poi.longitude), 16);
    final sheet = _scaffoldKey.currentState!.showBottomSheet(
      (context) => DraggableScrollableSheet(
        initialChildSize: .56,
        minChildSize: .2,
        maxChildSize: .9,
        expand: false,
        shouldCloseOnMinExtent: true,
        snap: true,
        snapSizes: const [.56],
        snapAnimationDuration: const Duration(milliseconds: 200),
        builder: (_, scroll) => PlaceDetailsSheet(
          place: poi,
          scrollController: scroll,
          onCollect: (place) async {
            await _dismissDetails();
            if (mounted) await _collection(poi: place);
          },
          onPlaceSelected: _details,
        ),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      showDragHandle: false,
      enableDrag: false,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
    );
    _detailSheet = sheet;
    final closed = sheet.closed.whenComplete(() {
      if (mounted && identical(_detailSheet, sheet)) {
        setState(() {
          _detailSheet = null;
          _focusedPlace = null;
        });
        _queueArea(_center);
      }
    });
    final lift = MediaQuery.sizeOf(context).height * .28;
    if (_native) {
      await _nativeController?.focus(
        LatLng(poi.latitude, poi.longitude),
        16,
        lift,
      );
    } else if (_fallbackReady) {
      _fallback.move(
        LatLng(poi.latitude, poi.longitude),
        16,
        offset: Offset(0, -lift),
      );
    }
    await closed;
  }

  Future<void> _search() async {
    _interactionEpoch++;
    final result = await showSearch<Poi?>(
      context: context,
      delegate: PlaceSearch(_center.latitude, _center.longitude),
    );
    if (result != null && mounted) {
      await _details(result);
    }
  }

  Future<void> _collection({Poi? poi, bool manual = false}) async {
    if (_collecting) return;
    _interactionEpoch++;
    await _dismissDetails();
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _collecting = true);
    var saved = false;
    final selected = await showModalBottomSheet<Poi>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      showDragHandle: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: .6,
        minChildSize: .25,
        maxChildSize: .92,
        expand: false,
        shouldCloseOnMinExtent: true,
        builder: (_, scroll) => PoiSheet(
          center: _center,
          scrollController: scroll,
          initialPoi: poi,
          startManual: manual,
          onDetails: (value) => Navigator.pop(sheetContext, value),
          onSaved: () {
            saved = true;
            Navigator.pop(sheetContext);
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _collecting = false);
    if (saved) {
      _savedNoticeTimer?.cancel();
      setState(() => _savedNotice = true);
      _savedNoticeTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _savedNotice = false);
      });
    }
    if (selected != null) await _details(selected);
  }

  void _backfill(CollectionProvider provider) {
    if (_backfilled || !provider.loaded) return;
    _backfilled = true;
    final places = provider.all
        .map((v) => v.place)
        .where(
          (p) =>
              p.province?.isNotEmpty != true || p.district?.isNotEmpty != true,
        )
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final p in places) {
        if (!mounted) return;
        try {
          final geo = await PoiSearchService.reverseGeocode(
            p.latitude,
            p.longitude,
          );
          await provider.enrichPlace(
            p.copyWith(
              province: geo.province,
              city: geo.city,
              district: geo.district,
              country: geo.country,
              adcode: geo.adcode,
              address: p.address?.isNotEmpty == true ? p.address : geo.address,
            ),
          );
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    _markers = AdministrativeClusters.build(provider.filtered, _zoom);
    _backfill(provider);
    _syncMarkers();
    return PopScope(
      canPop: _savedPlace == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeSavedPlace();
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: LayoutBuilder(
          builder: (context, constraints) => ValueListenableBuilder<double>(
            valueListenable: _savedExtent,
            builder: (context, extent, map) => Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  bottom: constraints.maxHeight * extent,
                  child: map!,
                ),
                if (_savedPlace != null)
                  NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      _savedExtent.value = notification.extent;
                      if (notification.extent <=
                          notification.minExtent + .001) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _closeSavedPlace();
                        });
                      }
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      initialChildSize: .48,
                      minChildSize: .2,
                      maxChildSize: .78,
                      snap: true,
                      snapSizes: const [.48],
                      builder: (context, scroll) => DetailSheet(
                        view:
                            provider.all
                                .where((v) => v.id == _savedPlace!.id)
                                .firstOrNull ??
                            _savedPlace!,
                        scrollController: scroll,
                        onClose: _closeSavedPlace,
                        onDetails: () =>
                            _details(Poi.fromPlace(_savedPlace!.place)),
                      ),
                    ),
                  ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 4,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _savedNotice
                          ? Center(
                              key: const ValueKey('saved-notice'),
                              child: Semantics(
                                liveRegion: true,
                                child: Material(
                                  elevation: 4,
                                  shadowColor: AppColors.ink.withValues(
                                    alpha: .15,
                                  ),
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 9,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: AppColors.accent,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          '已收藏',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: _native
                        ? NativeAMap(
                            apiKey: AppConfig.amapAndroidApiKey,
                            center: _center,
                            zoom: _zoom,
                            locationEnabled: _locationEnabled,
                            logoBottomInset: _savedPlace != null
                                ? 20
                                : _focusedPlace == null
                                ? 110
                                : MediaQuery.sizeOf(context).height -
                                      MediaQuery.paddingOf(context).top -
                                      32,
                            onCreated: (controller) {
                              setState(() {
                                _nativeController = controller;
                                _signature = '';
                              });
                              final focused = _focusedPlace;
                              if (focused == null || _savedPlace != null) {
                                controller.move(_center, _zoom);
                              } else {
                                controller.focus(
                                  LatLng(focused.latitude, focused.longitude),
                                  16,
                                  MediaQuery.sizeOf(context).height * .28,
                                );
                              }
                            },
                            onCamera: _camera,
                            onTap: (_) {},
                            onLongPress: (point) {
                              _move(point, _zoom);
                              _collection(manual: true);
                            },
                            onPoi: (p) {
                              final poi = Poi(
                                id: p['id'] as String? ?? '',
                                name: p['name'] as String? ?? '',
                                addr: '',
                                distance: '',
                                latitude: (p['lat'] as num).toDouble(),
                                longitude: (p['lng'] as num).toDouble(),
                              );
                              _move(LatLng(poi.latitude, poi.longitude), 16);
                              _collection(poi: poi);
                            },
                            onMarker: _markerTap,
                          )
                        : FlutterMap(
                            mapController: _fallback,
                            options: MapOptions(
                              initialCenter: _center,
                              initialZoom: _zoom,
                              maxZoom: 19,
                              onMapReady: () {
                                _fallbackReady = true;
                              },
                              onPositionChanged: (camera, _) => _camera(
                                NativeMapCamera(camera.center, camera.zoom),
                              ),
                              onLongPress: (_, point) {
                                _move(point, _zoom);
                                _collection(manual: true);
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x={x}&y={y}&z={z}',
                                subdomains: const ['1', '2', '3', '4'],
                                userAgentPackageName: 'com.tastemap.tastemap',
                              ),
                              MarkerLayer(
                                markers: [
                                  if (_focusedPlace != null &&
                                      _savedPlace == null)
                                    Marker(
                                      point: LatLng(
                                        _focusedPlace!.latitude,
                                        _focusedPlace!.longitude,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 36,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ..._markers.map(
                                    (g) => Marker(
                                      point: g.point,
                                      width: g.isPlace ? 180 : 140,
                                      height: g.isPlace ? 96 : 44,
                                      alignment: g.isPlace
                                          ? Marker.computePixelAlignment(
                                              width: 180,
                                              height: 96,
                                              left: 90,
                                              top: 76,
                                            )
                                          : Alignment.center,
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () => _markerTap(g.id),
                                          child: g.isPlace
                                              ? FavoriteMarker(
                                                  name: g.title,
                                                  tag: g.members.first.tag,
                                                  visited:
                                                      g.members.first.visited,
                                                )
                                              : Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.mapFavorite,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${g.title} · ${g.members.length}',
                                                    style: const TextStyle(
                                                      color: AppColors.ink,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                if (_focusedPlace == null)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _surface(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 13,
                                    ),
                                    child: ValueListenableBuilder<String>(
                                      valueListenable: _areaLabel,
                                      builder: (_, label, _) => Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _button(Icons.search, _search, '搜索'),
                              const SizedBox(width: 10),
                              _button(Icons.person_outline, _profile, '我的'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: const Text('全部'),
                                    selected: provider.selectedTag == null,
                                    onSelected: (_) => provider.setTag(null),
                                  ),
                                ),
                                ...provider.tagOptions.map(
                                  (tag) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(tag.label),
                                      selected: provider.selectedTag == tag,
                                      onSelected: (_) => provider.setTag(tag),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_focusedPlace == null) _centerPin(),
                if (_focusedPlace == null)
                  Positioned(
                    right: 20,
                    bottom: MediaQuery.paddingOf(context).bottom + 20,
                    child: _surface(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '朝北',
                            constraints: const BoxConstraints.tightFor(
                              width: 52,
                              height: 52,
                            ),
                            onPressed: () {
                              if (_native) {
                                _nativeController?.north();
                              } else {
                                _fallback.rotate(0);
                              }
                            },
                            icon: const Icon(
                              Icons.navigation_outlined,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            tooltip: _locating ? '定位中' : '定位',
                            constraints: const BoxConstraints.tightFor(
                              width: 52,
                              height: 52,
                            ),
                            onPressed: () => _locate(interactive: true),
                            icon: Icon(
                              _locating
                                  ? Icons.location_searching
                                  : Icons.my_location,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_tip && _focusedPlace == null)
                  Positioned(
                    left: 20,
                    right: 76,
                    bottom: MediaQuery.paddingOf(context).bottom + 110,
                    child: _surface(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Text('长按地图收藏地点'),
                            ),
                          ),
                          IconButton(
                            tooltip: '关闭引导',
                            onPressed: () => setState(() => _tip = false),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_focusedPlace == null)
                  Positioned(
                    left: 20,
                    bottom: MediaQuery.paddingOf(context).bottom + 20,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (MediaQuery.sizeOf(context).width / 2 - 48)
                            .clamp(100.0, 145.0),
                      ),
                      child: _surface(
                        child: TextButton.icon(
                          onPressed: _collections,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: const Icon(Icons.bookmark_outline, size: 20),
                          label: const Text(
                            '我的收藏',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_focusedPlace == null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.paddingOf(context).bottom + 20,
                    child: Center(
                      child: Tooltip(
                        message: '添加地点',
                        child: FilledButton(
                          onPressed: () => _collection(),
                          onLongPress: () => _collection(manual: true),
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(14),
                            minimumSize: const Size(52, 52),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _centerPin() => Center(
    child: RepaintBoundary(
      child: Transform.translate(
        offset: const Offset(0, -21),
        child: Semantics(
          label: '收藏地图中心位置',
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _collection,
            child: AnimatedScale(
              scale: _collecting ? .94 : 1,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 42,
                  color: AppColors.accent,
                  shadows: [
                    Shadow(color: Colors.white, blurRadius: 3),
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _surface({required Widget child}) => Material(
    color: Colors.white.withValues(alpha: .96),
    elevation: 2,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(24),
    child: child,
  );
  Widget _button(IconData icon, VoidCallback onTap, String label) => _surface(
    child: IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: Icon(icon, size: 20),
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
    ),
  );
}
