import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show Marker, MapController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/realtime_location_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/common/osm_map.dart';
import '../../widgets/feed/live_feed_widget.dart';

/// 실시간 미션 맵. 참여자들이 지도 위에서 움직이는 것을 표시.
///
/// Host 뷰: 전체 참여자 마커 + 체크포인트 핀
/// Participant 뷰: 본인 위치 + 목표지점
///
/// Supabase Broadcast 채널 'location:{clueId}'로 위치 공유.
/// LocationService.startLocationStream(distanceFilter: 10)으로 10m 이동마다 전송.
class MissionMapScreen extends ConsumerStatefulWidget {
  final String clueId;
  final bool isHost;
  final List<Map<String, dynamic>> checkpoints;

  const MissionMapScreen({
    super.key,
    required this.clueId,
    this.isHost = false,
    this.checkpoints = const [],
  });

  @override
  ConsumerState<MissionMapScreen> createState() => _MissionMapScreenState();
}

class _MissionMapScreenState extends ConsumerState<MissionMapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _locationSubscription;
  LatLng _currentPosition = const LatLng(37.5666, 126.9784);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await _locationService.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      try {
        _mapController.move(_currentPosition, 15);
      } catch (_) {/* 맵 미렌더 상태면 무시 */}

      // 위치 스트림 시작 (10m 이동마다)
      _locationService.startLocationStream(distanceFilter: 10);
      _locationSubscription = _locationService.locationStream.listen((pos) {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) return;

        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });

        // Broadcast로 위치 공유
        ref.read(realtimeLocationProvider(widget.clueId).notifier)
            .broadcastLocation(
          userId: userId,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.stopLocationStream();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participantLocations =
        ref.watch(realtimeLocationProvider(widget.clueId));

    // 마커 생성 — 체크포인트(빨강 핀) + 참여자(파랑 도트) + 내 위치
    final markers = <Marker>[];

    for (var i = 0; i < widget.checkpoints.length; i++) {
      final cp = widget.checkpoints[i];
      final lat = cp['target_latitude'] as double?;
      final lng = cp['target_longitude'] as double?;
      if (lat != null && lng != null) {
        markers.add(osmPin(LatLng(lat, lng)));
      }
    }

    for (final entry in participantLocations.entries) {
      final loc = entry.value;
      markers.add(osmDot(LatLng(loc.latitude, loc.longitude)));
    }

    // 내 위치
    markers.add(osmDot(_currentPosition, color: AppColors.brandGreen));

    return Scaffold(
      appBar: AppBar(
        title: const Text('미션 맵'),
        centerTitle: true,
        actions: [
          // 참여자 수 표시
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 18),
                  const SizedBox(width: 4),
                  Text('${participantLocations.length}명'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 지도 — flutter_map(OSM, 전 플랫폼 호환)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                OsmMap(
                  controller: _mapController,
                  center: _currentPosition,
                  zoom: 15,
                  markers: markers,
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'myloc',
                    backgroundColor: AppColors.bgElevated,
                    foregroundColor: AppColors.brandBlue,
                    onPressed: () =>
                        _mapController.move(_currentPosition, 15),
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),

          // 실시간 피드 (하단)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      '실시간 피드',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: LiveFeedWidget(clueId: widget.clueId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
