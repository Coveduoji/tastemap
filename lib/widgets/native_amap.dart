import 'dart:ui' as ui;
import 'package:amap_map/amap_map.dart' as amap;
import 'package:x_amap_base/x_amap_base.dart' as base;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart';

class NativeMapCamera {
  final LatLng center;
  final double zoom;
  const NativeMapCamera(this.center, this.zoom);
}

/// App-level coordinate/style adapter. Lifecycle and platform communication belong to amap_map.
class NativeMapController {
  final amap.AMapController map;
  final _NativeAMapState _view;
  NativeMapController._(this.map, this._view);
  Future<void> move(LatLng point, double zoom) => map.moveCamera(
    amap.CameraUpdate.newLatLngZoom(
      base.LatLng(point.latitude, point.longitude),
      zoom,
    ),
    duration: 300,
  );
  Future<void> north() => map.moveCamera(
    amap.CameraUpdate.newCameraPosition(
      amap.CameraPosition(
        target: _view._camera.target,
        zoom: _view._camera.zoom,
      ),
    ),
  );
  Future<void> focus(LatLng point, double zoom, double lift) async {
    await map.moveCamera(
      amap.CameraUpdate.newLatLngZoom(
        base.LatLng(point.latitude, point.longitude),
        zoom,
      ),
      animated: false,
    );
    await map.moveCamera(amap.CameraUpdate.scrollBy(0, lift), duration: 300);
  }

  Future<void> clearCache() => map.clearDisk();
  Future<void> markers(List<Map<String, dynamic>> values) =>
      _view._markers(values);
}

class NativeAMap extends StatefulWidget {
  final String apiKey;
  final LatLng center;
  final double zoom;
  final bool locationEnabled;
  final double logoBottomInset;
  final ValueChanged<NativeMapController> onCreated;
  final ValueChanged<NativeMapCamera> onCamera;
  final ValueChanged<LatLng> onTap, onLongPress;
  final ValueChanged<Map> onPoi;
  final ValueChanged<String> onMarker;
  const NativeAMap({
    super.key,
    required this.apiKey,
    required this.center,
    required this.zoom,
    this.locationEnabled = false,
    this.logoBottomInset = 110,
    required this.onCreated,
    required this.onCamera,
    required this.onTap,
    required this.onLongPress,
    required this.onPoi,
    required this.onMarker,
  });
  @override
  State<NativeAMap> createState() => _NativeAMapState();
}

class _NativeAMapState extends State<NativeAMap> {
  late amap.CameraPosition _camera;
  Set<amap.Marker> _points = {};
  int _version = 0;
  final Map<String, Future<amap.BitmapDescriptor>> _icons = {};
  @override
  void initState() {
    super.initState();
    _camera = amap.CameraPosition(
      target: base.LatLng(widget.center.latitude, widget.center.longitude),
      zoom: widget.zoom,
    );
  }

  Future<void> _markers(List<Map<String, dynamic>> values) async {
    final version = ++_version;
    final points = await Future.wait(
      values.map((value) async {
        final key = value['cluster'] == true
            ? 'region:${value['title']}:${value['count']}'
            : 'pin:${value['label'] == true ? value['title'] : ''}:${value['icon']}:${value['visited']}';
        if (_icons.length > 128) _icons.clear();
        final icon = await _icons.putIfAbsent(key, () => _icon(value));
        return amap.Marker(
          position: base.LatLng(
            (value['lat'] as num).toDouble(),
            (value['lng'] as num).toDouble(),
          ),
          anchor: value['label'] == true && value['cluster'] != true
              ? const Offset(.5, 76 / 96)
              : const Offset(.5, .5),
          icon: icon,
          infoWindowEnable: false,
          onTap: (_) => widget.onMarker(value['id'] as String),
        )..setIdForCopy(value['id'] as String);
      }),
    );
    if (mounted && version == _version) {
      setState(() => _points = points.toSet());
    }
  }

  // Drawing the app's tag artwork is business styling; marker management is the plugin's.
  Future<amap.BitmapDescriptor> _icon(Map<String, dynamic> value) async {
    final cluster = value['cluster'] == true;
    final favorite = cluster || value['label'] == true;
    final labelled = !cluster && value['label'] == true;
    final label = labelled
        ? (TextPainter(
            text: TextSpan(
              text: value['title'] as String,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: 156))
        : null;
    final text = cluster
        ? '${value['title']} · ${value['count']}'
        : String.fromCharCode(
            labelled ? Icons.star_rounded.codePoint : value['icon'] as int,
          );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: cluster ? null : 'MaterialIcons',
          fontSize: cluster
              ? 12
              : labelled
              ? 40
              : 16,
          fontWeight: cluster ? FontWeight.w600 : null,
          color: labelled
              ? AppColors.mapFavorite
              : cluster
              ? AppColors.ink
              : Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 160);
    final size = Size(
      cluster
          ? painter.width + 22
          : labelled
          ? (label!.width + 24).clamp(44.0, double.infinity)
          : 30,
      labelled ? 96 : 30,
    );
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    if (labelled) {
      final bubble = RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 2, size.width - 2, 26),
        const Radius.circular(13),
      );
      canvas.drawRRect(bubble, Paint()..color = Colors.white);
      canvas.drawRRect(
        bubble,
        Paint()
          ..color = AppColors.mapFavorite
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final tip = ui.Path()
        ..moveTo(size.width / 2 - 6, 27)
        ..lineTo(size.width / 2, 35)
        ..lineTo(size.width / 2 + 6, 27);
      canvas.drawPath(tip, Paint()..color = Colors.white);
      canvas.drawPath(
        ui.Path()
          ..moveTo(size.width / 2 - 6, 28)
          ..lineTo(size.width / 2, 35)
          ..lineTo(size.width / 2 + 6, 28),
        Paint()
          ..color = AppColors.mapFavorite
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      label!.paint(
        canvas,
        Offset((size.width - label.width) / 2, 2 + (26 - label.height) / 2),
      );
    }
    final markerRect = labelled
        ? Rect.fromLTWH((size.width - 40) / 2, 56, 40, 40)
        : Offset.zero & size;
    if (labelled) {
      final outline = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'MaterialIcons',
            fontSize: 40,
            foreground: Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      outline.paint(
        canvas,
        Offset(
          markerRect.left + (markerRect.width - outline.width) / 2,
          markerRect.top + (markerRect.height - outline.height) / 2,
        ),
      );
      outline.dispose();
    } else {
      final shape = RRect.fromRectAndRadius(
        markerRect,
        const Radius.circular(15),
      );
      canvas.drawRRect(
        shape,
        Paint()..color = favorite ? AppColors.mapFavorite : AppColors.accent,
      );
      canvas.drawRRect(
        shape.deflate(.75),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    painter.paint(
      canvas,
      Offset(
        markerRect.left + (markerRect.width - painter.width) / 2,
        markerRect.top + (markerRect.height - painter.height) / 2,
      ),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (size.width * ratio).ceil(),
      (size.height * ratio).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    painter.dispose();
    label?.dispose();
    return amap.BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    amap.AMapInitializer.init(
      context,
      apiKey: base.AMapApiKey(androidKey: widget.apiKey, iosKey: ''),
    );
    amap.AMapInitializer.updatePrivacyAgree(
      const base.AMapPrivacyStatement(
        hasContains: true,
        hasShow: true,
        hasAgree: true,
      ),
    );
    return amap.AMapWidget(
      initialCameraPosition: _camera,
      mapType: amap.MapType.normal,
      markers: _points,
      myLocationStyleOptions: amap.MyLocationStyleOptions(
        widget.locationEnabled,
        circleFillColor: AppColors.accent.withValues(alpha: .08),
        circleStrokeColor: Colors.transparent,
      ),
      touchPoiEnabled: true,
      scaleEnabled: true,
      compassEnabled: false,
      buildingsEnabled: true,
      logoBottomMargin:
          (widget.logoBottomInset * MediaQuery.devicePixelRatioOf(context))
              .round(),
      onMapCreated: (controller) {
        widget.onCreated(NativeMapController._(controller, this));
        widget.onCamera(NativeMapCamera(widget.center, widget.zoom));
      },
      onCameraMoveEnd: (camera) {
        _camera = camera;
        widget.onCamera(
          NativeMapCamera(
            LatLng(camera.target.latitude, camera.target.longitude),
            camera.zoom,
          ),
        );
      },
      onTap: (point) => widget.onTap(LatLng(point.latitude, point.longitude)),
      onLongPress: (point) =>
          widget.onLongPress(LatLng(point.latitude, point.longitude)),
      onPoiTouched: (poi) {
        final point = poi.latLng;
        if (point == null) return;
        widget.onPoi({
          'id': poi.id,
          'name': poi.name,
          'lat': point.latitude,
          'lng': point.longitude,
        });
      },
    );
  }
}
