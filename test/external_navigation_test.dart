import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:map_launcher/map_launcher_platform_interface.dart';
import 'package:tastemap/data/external_navigation.dart';
import 'import_service_test.dart' show sample;

class FakeMaps extends MapLauncherPlatform {
  Set<String> installed = {};
  final calls = <({String url, String? package})>[];
  Future<void> Function(String? package)? onLaunch;
  int probes = 0;
  @override
  MapPlatform get platform => MapPlatform.android;
  @override
  Future<Set<String>> getInstalledMaps(List<MapApp> maps) async {
    probes++;
    return installed;
  }

  @override
  Future<void> launch(String url, {String? androidPackageName}) async {
    calls.add((url: url, package: androidPackageName));
    await onLaunch?.call(androidPackageName);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MapLauncherPlatform previous;
  late FakeMaps maps;
  late List<String> copied;
  setUp(() {
    previous = MapLauncherPlatform.instance;
    maps = FakeMaps();
    MapLauncherPlatform.instance = maps;
    copied = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
  });
  tearDown(() {
    MapLauncherPlatform.instance = previous;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('已安装地图优先唤起高德原生导航，传入目的地，不打开网页', () async {
    maps.installed = {'amap', 'baidu', 'google'};
    final view = sample('a');
    expect(await ExternalNavigation.open(view), NavigationResult.opened);
    expect(maps.calls.single.package, 'com.autonavi.minimap');
    final uri = Uri.parse(maps.calls.single.url);
    expect(uri.scheme, 'amapuri');
    expect(uri.queryParameters['dlat'], '${view.latitude}');
    expect(uri.queryParameters['dlon'], '${view.longitude}');
    expect(uri.queryParameters['dname'], view.name);
    expect(uri.queryParameters['dev'], '0');
    expect(copied, isEmpty);
  });
  test('无应用时直接复制地址，忽略仅可用浏览器打开的地图', () async {
    final view = sample('a');
    expect(await ExternalNavigation.open(view), NavigationResult.copied);
    expect(maps.calls, isEmpty);
    expect(copied.single, ExternalNavigation.address(view));
  });
  test('一个应用明确拒绝时尝试下一个，百度使用当前位置与高德坐标类型', () async {
    maps.installed = {'amap', 'baidu'};
    maps.onLaunch = (package) async {
      if (package == 'com.autonavi.minimap') {
        throw const MapHandoffException('not available');
      }
    };
    expect(await ExternalNavigation.open(sample('a')), NavigationResult.opened);
    expect(maps.calls.length, 2);
    expect(maps.calls.last.package, 'com.baidu.BaiduMap');
    final params = Uri.parse(maps.calls.last.url).queryParameters;
    expect(params['origin'], '我的位置');
    expect(params['coord_type'], 'gcj02');
    expect(copied, isEmpty);
  });
  test('所有本机应用拒绝时复制地址，不降级打开浏览器', () async {
    maps.installed = {'google'};
    maps.onLaunch = (_) async =>
        throw const MapHandoffException('not available');
    expect(await ExternalNavigation.open(sample('a')), NavigationResult.copied);
    expect(maps.calls.length, 1);
    expect(maps.calls.single.package, 'com.google.android.apps.maps');
    expect(copied.length, 1);
  });
  test('结果未知或系统阻止时不再弹出第二个应用', () async {
    for (final error in [
      StateError('unknown'),
      const MapHandoffException('blocked', blocked: true),
    ]) {
      maps.calls.clear();
      copied.clear();
      maps.installed = {'amap', 'baidu'};
      maps.onLaunch = (_) async => throw error;
      expect(
        await ExternalNavigation.open(sample('a')),
        NavigationResult.copied,
      );
      expect(maps.calls.length, 1);
      expect(copied.length, 1);
    }
  });
  test('快速重复点击只执行一次唤起', () async {
    maps.installed = {'amap'};
    final handoff = Completer<void>();
    maps.onLaunch = (_) => handoff.future;
    final first = ExternalNavigation.open(sample('a'));
    final second = ExternalNavigation.open(sample('a'));
    await Future<void>.delayed(Duration.zero);
    expect(maps.calls.length, 1);
    handoff.complete();
    expect(await first, NavigationResult.opened);
    expect(await second, NavigationResult.opened);
    expect(maps.probes, 1);
  });
}
