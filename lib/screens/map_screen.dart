import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/collection_view.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/detail_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/pin_marker.dart';
import '../widgets/poi_sheet.dart';
import 'profile_screen.dart';

const LatLng kDefaultCenter = LatLng(39.9092, 116.3974); // 北京（高德国内瓦片覆盖）
const double kDefaultZoom = 13.5;

/// 地图首页：全屏地图 + 浮动 UI（无底部 Tab，DDR-01）。
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLngBounds? _visibleBounds;
  LatLng _center = kDefaultCenter;
  double _zoom = kDefaultZoom;
  String? _cityName;
  bool _showSheet = false;
  bool _startManual = false;
  final GlobalKey<PoiSheetState> _poiSheetKey = GlobalKey<PoiSheetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestLocation());
  }

  Future<bool> _requestLocation({bool notify = false}) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final granted = await Geolocator.requestPermission();
        if (granted != LocationPermission.whileInUse &&
            granted != LocationPermission.always) {
          if (notify) _showLocationGuide();
          return false; // 静默降级到默认坐标（首次启动不强求定位）
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (notify) _showLocationGuide();
        return false;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (notify) _showLocationGuide();
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(forceLocationManager: true),
      );
      if (!mounted) return false;
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_center, kDefaultZoom);
      _reverseGeocode(LatLng(pos.latitude, pos.longitude));
      return true;
    } catch (_) {
      // 定位失败：保持默认坐标，不阻塞
      if (notify) _showLocationGuide();
      return false;
    }
  }

  Future<void> _locateMe() async {
    await _requestLocation(notify: true);
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(
        'https://restapi.amap.com/v3/geocode/regeo'
        '?key=${AppConfig.amapWebApiKey}'
        '&location=${pos.longitude},${pos.latitude}',
      ));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final component = (decoded['regeocode']
              as Map<String, dynamic>?)?['addressComponent']
          as Map<String, dynamic>?;
      // 高德字段可能是字符串、空数组 []（直辖市 city）或 null，需健壮解析
      String? readStr(dynamic v) {
        if (v is String && v.isNotEmpty) return v;
        if (v is List && v.isNotEmpty) return v.first.toString();
        return null;
      }

      final province = readStr(component?['province']);
      final city = readStr(component?['city']);
      final district = readStr(component?['district']);
      final base = city ?? province; // 直辖市 city 为空时回退到 province
      if (base != null && mounted) {
        final label = (district != null && district != base)
            ? '$base · $district'
            : base;
        setState(() => _cityName = label);
      }
      client.close();
    } catch (_) {
      // 逆地理失败：保持「当前位置」占位
    }
  }

  void _showLocationGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('未获取定位，当前显示默认位置（北京）')),
    );
  }

  void _onSelectLocation(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 15);
  }

  void _openCollectionFlow() {
    setState(() {
      _showSheet = true;
      _startManual = false;
    });
  }

  /// 长按「+」：跳过附近地点列表，直接对当前钉子位置（拖图后的地图中心）命名。
  /// 用于地图上没有对应 POI 的位置，如秋千、拍照机位——先拖图把钉子放准，再长按命名。
  void _onFabLongPress() {
    HapticFeedback.mediumImpact();
    if (_showSheet) {
      _poiSheetKey.currentState?.startManualEntry();
    } else {
      setState(() {
        _showSheet = true;
        _startManual = true;
      });
    }
  }

  Future<void> _openDetail(CollectionView view) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetailSheet(view: view),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  List<Marker> _buildMarkers(List<CollectionView> views) {
    // 按当前缩放级别做距离聚类：40px 视距内的点合并为一个数字气泡（P1 聚合）
    final threshold = 40 * 360 / (256 * math.pow(2, _zoom));
    final clusters = <_Cluster>[];
    for (final v in views) {
      _Cluster? target;
      for (final c in clusters) {
        if (c.distanceTo(v) < threshold) {
          target = c;
          break;
        }
      }
      if (target != null) {
        target.add(v);
      } else {
        clusters.add(_Cluster(v));
      }
    }

    final markers = clusters.map((c) {
      if (c.views.length == 1) {
        final v = c.views.first;
        return Marker(
          point: LatLng(v.latitude, v.longitude),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _openDetail(v),
            child: PinMarker(tag: v.tag, visited: v.visited),
          ),
        );
      }
      return Marker(
        point: LatLng(c.lat, c.lng),
        width: 40,
        height: 40,
        child: _clusterBubble(c.views.length),
      );
    }).toList();

    return markers;
  }

  Widget _clusterBubble(int count) {
    return GestureDetector(
      onTap: _zoomIn,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.warmWhite, width: 2.5),
          boxShadow: [
            BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: AppText.chip.copyWith(color: AppColors.warmWhite),
        ),
      ),
    );
  }

  void _zoomIn() {
    final cam = _mapController.camera;
    _mapController.move(cam.center, cam.zoom + 1);
  }

  int _nearbyCount(List<CollectionView> views) {
    final bounds = _visibleBounds;
    if (bounds == null) return 0;
    return views
        .where((v) => bounds.contains(LatLng(v.latitude, v.longitude)))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final views = provider.filtered;
    final nearby = _nearbyCount(views);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: kDefaultZoom,
              onMapReady: () {
                _visibleBounds = _mapController.camera.visibleBounds;
                _zoom = _mapController.camera.zoom;
                setState(() {});
              },
              onMapEvent: (e) {
                if (e is MapEventMoveEnd ||
                    e is MapEventFlingAnimationEnd) {
                  setState(() {
                    _visibleBounds = _mapController.camera.visibleBounds;
                    _zoom = _mapController.camera.zoom;
                    _center = _mapController.camera.center;
                  });
                  // 地图拖动后，以地图中心为准刷新附近地点
                  _poiSheetKey.currentState
                      ?.reloadNearby(_mapController.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x={x}&y={y}&z={z}',
                subdomains: const ['1', '2', '3', '4'],
                userAgentPackageName: 'com.tastemap.tastemap',
              ),
              MarkerLayer(markers: _buildMarkers(views)),
            ],
          ),

          // ── 顶部浮动 UI ──
          SafeArea(
            child: Column(
              children: [
                if (nearby > 0) _nearbyBadge(nearby),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      Expanded(child: _cityPill()),
                      const SizedBox(width: 10),
                      _iconBtn(Icons.search, _openCollectionFlow),
                      const SizedBox(width: 10),
                      _avatarBtn(_openProfile),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 空态 ──
          if (views.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: EmptyState(),
              ),
            ),

          // ── 中心钉子（拖图模式） ──
          if (_showSheet)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: const Icon(Icons.location_on, size: 34, color: AppColors.accent),
                  ),
                ),
              ),
            ),

          // ── 收藏弹层（非模态，地图可拖动） ──
          if (_showSheet)
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.5,
                maxChildSize: 0.75,
                expand: false,
                builder: (context, scrollController) => PoiSheet(
                  key: _poiSheetKey,
                  center: _center,
                  scrollController: scrollController,
                  startManual: _startManual,
                  onSelectLocation: _onSelectLocation,
                  onClose: () => setState(() => _showSheet = false),
                  onSaved: () {
                    setState(() => _showSheet = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ 已收藏'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── 定位按钮 ──
          Positioned(
            right: 16,
            bottom: 112,
            child: _iconBtn(Icons.my_location, _locateMe),
          ),

          // ── FAB ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 112,
            child: Center(
              child: GestureDetector(
                onTap: _openCollectionFlow,
                onLongPress: _onFabLongPress,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    size: 30,
                    color: AppColors.warmWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nearbyBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Text(
        '视野内 · $count 个收藏',
        style: AppText.caption.copyWith(color: AppColors.warmWhite),
      ),
    );
  }

  Widget _cityPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.warmWhite.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_cityName ?? '当前位置', style: AppText.cityName),
              Text('我的品味地图', style: AppText.caption),
            ],
          ),
          const Spacer(),
          const Text('▾', style: TextStyle(color: AppColors.stone, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.warmWhite.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: AppColors.ink),
      ),
    );
  }

  Widget _avatarBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.warmWhite, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.person, size: 17, color: AppColors.warmWhite),
      ),
    );
  }
}

class _Cluster {
  double lat;
  double lng;
  final List<CollectionView> views = [];

  _Cluster(CollectionView v)
      : lat = v.latitude,
        lng = v.longitude {
    views.add(v);
  }

  void add(CollectionView v) {
    views.add(v);
    lat = (lat * (views.length - 1) + v.latitude) / views.length;
    lng = (lng * (views.length - 1) + v.longitude) / views.length;
  }

  double distanceTo(CollectionView v) {
    final dLat = lat - v.latitude;
    final dLng = (lng - v.longitude) * math.cos(lat * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }
}
