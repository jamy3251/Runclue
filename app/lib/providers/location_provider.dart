import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

/// Singleton provider for [LocationService].
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// StateProvider holding the most recent known position, or null.
final currentLocationProvider = StateProvider<Position?>((ref) {
  return null;
});

/// FutureProvider that checks (and requests) location permission.
final locationPermissionProvider =
    FutureProvider<LocationPermission>((ref) async {
  final service = ref.watch(locationServiceProvider);
  var permission = await service.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await service.requestPermission();
  }

  return permission;
});

/// StreamProvider for continuous location updates.
///
/// Starts the location stream on first listen and stops it when
/// all listeners are gone.
final locationStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);
  service.startLocationStream();

  ref.onDispose(() {
    service.stopLocationStream();
  });

  return service.locationStream;
});
