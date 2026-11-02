import 'package:flutter/services.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:map_launcher/map_launcher_platform_interface.dart';
import '../models/collection_view.dart';

enum NavigationResult { opened, copied }

/// Detects installed maps and uses their native routing URLs. Never opens a browser.
class ExternalNavigation {
  static const maps = <MapApp>[
    MapApp.amap,
    MapApp.baidu,
    MapApp.tencent,
    MapApp.petal,
    MapApp.apple,
    MapApp.google,
    MapApp.googleGo,
    MapApp.waze,
    MapApp.here,
    MapApp.mapswithme,
    MapApp.osmand,
    MapApp.osmandplus,
    MapApp.magicEarth,
    MapApp.yandexMaps,
    MapApp.doubleGis,
    MapApp.mapyCz,
  ];
  static Future<NavigationResult>? _pending;

  static Future<NavigationResult> open(CollectionView view) =>
      _pending ??= _open(view).whenComplete(() => _pending = null);

  static String address(CollectionView view) {
    final street = view.place.address?.trim();
    return [
      view.name,
      view.city,
      if (street?.isNotEmpty == true)
        street
      else
        '${view.latitude}, ${view.longitude}',
    ].whereType<String>().where((s) => s.isNotEmpty).toSet().join(' · ');
  }

  static Future<NavigationResult> _open(CollectionView view) async {
    final platform = MapLauncherPlatform.instance;
    try {
      final available = await MapLauncher.getAvailableMaps(maps);
      final request = MapLauncher.directions(
        Location.coords(view.latitude, view.longitude, title: view.name),
      );
      for (final candidate in available.where((m) => m.isInstalled)) {
        var url = request.getUrl(map: candidate.map);
        if (url == null) continue;
        if (candidate.map.id == 'amap') {
          final uri = Uri.parse(url);
          url = uri
              .replace(
                queryParameters: {
                  ...uri.queryParameters,
                  'sourceApplication': '拾途',
                },
              )
              .toString();
        } else if (candidate.map.id == 'baidu') {
          final uri = Uri.parse(url);
          url = uri
              .replace(
                queryParameters: {
                  ...uri.queryParameters,
                  'origin': '我的位置',
                  'coord_type': 'gcj02',
                  'src':
                      '${platform.platform == MapPlatform.ios ? 'ios' : 'andr'}.com.tastemap.tastemap',
                },
              )
              .toString();
        }
        try {
          // Native package targeting avoids the request API's browser fallback.
          await platform.launch(
            url,
            androidPackageName: platform.platform == MapPlatform.android
                ? candidate.map.playStoreId
                : null,
          );
          return NavigationResult.opened;
        } on MapHandoffException catch (error) {
          if (error.blocked) break;
          // Only a confirmed rejected handoff permits trying the next app.
          continue;
        } catch (_) {
          break;
        }
      }
    } catch (_) {
      // Discovery errors still leave the destination available on the clipboard.
    }
    await Clipboard.setData(ClipboardData(text: address(view)));
    return NavigationResult.copied;
  }
}
