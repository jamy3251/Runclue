import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  /// Stream of location updates.
  Stream<Position> get locationStream => _locationController.stream;

  /// Get the current GPS position with error handling.
  Future<Position> getCurrentPosition() async {
    try {
      final permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is not granted. Please enable it in settings.',
        );
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable GPS.',
        );
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Failed to get current position: $e');
    }
  }

  /// Check the current location permission status.
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from the user.
  Future<LocationPermission> requestPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      return await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      // Cannot request again; user must enable in settings.
      return permission;
    }
    return permission;
  }

  /// Calculate the distance in meters between two coordinates using
  /// the Haversine formula.
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Check whether the user is within a given radius (in meters) of a target.
  bool isWithinRadius(
    double userLat,
    double userLng,
    double targetLat,
    double targetLng,
    double radiusMeters,
  ) {
    final distance = calculateDistance(userLat, userLng, targetLat, targetLng);
    return distance <= radiusMeters;
  }

  /// 현재 위치 → 목표 좌표의 방위각 (북쪽 0°, 시계방향)
  double bearingBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final lambda1 = _toRadians(lng1);
    final lambda2 = _toRadians(lng2);
    final y = sin(lambda2 - lambda1) * cos(phi2);
    final x = cos(phi1) * sin(phi2) -
        sin(phi1) * cos(phi2) * cos(lambda2 - lambda1);
    final theta = atan2(y, x);
    return (theta * 180 / pi + 360) % 360;
  }

  /// Start continuous location updates.
  void startLocationStream({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        _locationController.add(position);
      },
      onError: (error) {
        _locationController.addError(error);
      },
    );
  }

  /// Stop continuous location updates.
  void stopLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Clean up resources.
  void dispose() {
    stopLocationStream();
    _locationController.close();
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
