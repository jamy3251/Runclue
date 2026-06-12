import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config/theme.dart';

/// 전 플랫폼 공용 지도 — flutter_map + OpenStreetMap(CARTO 다크 타일).
///
/// google_maps_flutter 대체 (2026-06-12): 네이티브 SDK가 아니라 순수 Flutter
/// 렌더링이라 Android/iOS/웹/데스크톱에서 동일하게 동작하고 API 키가 필요 없다.
/// (기존 문제: iOS는 AppDelegate 키 설정 누락으로 미동작, 일부 안드로이드는
/// SurfaceView GPU 노이즈)
class OsmMap extends StatelessWidget {
  const OsmMap({
    super.key,
    required this.center,
    this.zoom = 16,
    this.markers = const [],
    this.circles = const [],
    this.onTap,
    this.onPositionChanged,
    this.controller,
    this.interactive = true,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final List<CircleMarker> circles;
  final void Function(LatLng latlng)? onTap;
  final void Function(LatLng center)? onPositionChanged;
  final MapController? controller;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: onTap == null ? null : (_, latlng) => onTap!(latlng),
        onPositionChanged: onPositionChanged == null
            ? null
            : (camera, _) => onPositionChanged!(camera.center),
        backgroundColor: AppColors.bgBase,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.runclue.app',
        ),
        if (circles.isNotEmpty) CircleLayer(circles: circles),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
        const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              '© OpenStreetMap © CARTO',
              style: TextStyle(fontSize: 9, color: Colors.white38),
            ),
          ),
        ),
      ],
    );
  }
}

/// 표준 핀 마커 (구글맵 BitmapDescriptor 대체).
Marker osmPin(LatLng point, {Color color = AppColors.brandRed, double size = 36}) {
  return Marker(
    point: point,
    width: size,
    height: size,
    alignment: Alignment.topCenter,
    child: Icon(Icons.location_pin, color: color, size: size, shadows: const [
      Shadow(color: Colors.black54, blurRadius: 4),
    ],),
  );
}

/// 참가자/내 위치 도트 마커.
Marker osmDot(LatLng point, {Color color = AppColors.brandBlue, double size = 16}) {
  return Marker(
    point: point,
    width: size,
    height: size,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
    ),
  );
}
