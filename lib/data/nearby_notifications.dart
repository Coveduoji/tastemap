import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../state/collection_provider.dart';
import 'collection_repository.dart';
import 'poi_search.dart';

class NearbyNotifications with WidgetsBindingObserver {
  static final instance = NearbyNotifications._();
  NearbyNotifications._();
  final _plugin = FlutterLocalNotificationsPlugin();
  final _repo = CollectionRepository();
  CollectionProvider? _provider;
  StreamSubscription<Position>? _positions;
  Future<void>? _initializing;
  bool _busy = false;
  DateTime? _lastCheck;
  Future<void> _initialize() => _initializing ??= () async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_pin'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();
  Future<void> attach(CollectionProvider provider) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _provider = provider;
    await _initialize();
    WidgetsBinding.instance.addObserver(this);
    provider.addListener(_settingsChanged);
    _settingsChanged();
  }

  Future<bool> enable() async {
    await _initialize();
    final granted = Platform.isAndroid
        ? await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission()
        : await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true);
    if (granted != true) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void _settingsChanged() {
    if (_provider?.nearbyReminders != true ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      _positions?.cancel();
      _positions = null;
      return;
    }
    _positions ??=
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 100,
          ),
        ).listen(
          _check,
          onError: (_) {
            _positions?.cancel();
            _positions = null;
          },
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _settingsChanged();
    } else {
      _positions?.cancel();
      _positions = null;
    }
  }

  Future<void> _check(Position position) async {
    if (_busy ||
        _provider?.nearbyReminders != true ||
        (_lastCheck != null &&
            DateTime.now().difference(_lastCheck!) <
                const Duration(seconds: 30))) {
      return;
    }
    _busy = true;
    _lastCheck = DateTime.now();
    try {
      final converted = await PoiSearchService.convertGps(
        position.latitude,
        position.longitude,
      );
      if (converted == null) return;
      final key =
          'notified_${DateTime.now().toIso8601String().substring(0, 10)}';
      final seen = ((jsonDecode(await _repo.getSetting(key) ?? '[]')) as List)
          .whereType<String>()
          .toSet();
      for (final view in _provider!.all) {
        final distance = const Distance().as(
          LengthUnit.Meter,
          LatLng(converted.latitude, converted.longitude),
          LatLng(view.latitude, view.longitude),
        );
        if (distance > 150 || seen.contains(view.id)) continue;
        await _plugin.show(
          view.id.hashCode & 0x7fffffff,
          view.name,
          '就在附近 · ${distance.round()}米',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'nearby_places',
              '附近收藏',
              importance: Importance.defaultImportance,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
        seen.add(view.id);
      }
      await _repo.setSetting(key, jsonEncode(seen.toList()));
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  Future<void> test() async {
    await _initialize();
    await _plugin.show(
      0,
      '品味地图',
      '提醒已开启',
      const NotificationDetails(
        android: AndroidNotificationDetails('nearby_places', '附近收藏'),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
