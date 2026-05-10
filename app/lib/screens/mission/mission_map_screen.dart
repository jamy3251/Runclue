import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/auth_provider.dart';
import '../../providers/realtime_location_provider.dart';
import '../../services/location_service.dart';
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
  GoogleMapController? _mapController;
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
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );

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
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participantLocations =
        ref.watch(realtimeLocationProvider(widget.clueId));

    // 참여자 마커 생성
    final markers = <Marker>{};

    // 체크포인트 핀
    for (var i = 0; i < widget.checkpoints.length; i++) {
      final cp = widget.checkpoints[i];
      final lat = cp['target_latitude'] as double?;
      final lng = cp['target_longitude'] as double?;
      if (lat != null && lng != null) {
        markers.add(Marker(
          markerId: MarkerId('checkpoint_$i'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: cp['title'] ?? 'Step ${i + 1}'),
        ));
      }
    }

    // 참여자 마커
    for (final entry in participantLocations.entries) {
      final loc = entry.value;
      markers.add(Marker(
        markerId: MarkerId('user_${loc.userId}'),
        position: LatLng(loc.latitude, loc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: loc.nickname ?? loc.userId.substring(0, 8),
        ),
      ));
    }

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
          // 지도
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
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
