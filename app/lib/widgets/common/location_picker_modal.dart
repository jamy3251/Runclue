import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show MapController;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:latlong2/latlong.dart';

import '../../config/theme.dart';
import '../../services/location_service.dart';
import 'osm_map.dart';

/// Result returned from the location picker.
class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// Full-screen modal for picking a location on Google Maps.
///
/// Usage:
/// ```dart
/// final result = await LocationPickerModal.show(context);
/// if (result != null) {
///   // use result.latitude, result.longitude, result.address
/// }
/// ```
class LocationPickerModal extends StatefulWidget {
  const LocationPickerModal({super.key});

  /// Show the location picker modal and return the selected location.
  static Future<LocationResult?> show(BuildContext context) {
    return Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LocationPickerModal(),
      ),
    );
  }

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  final _locationService = LocationService();

  // Default: Seoul City Hall
  LatLng _centerPosition = const LatLng(37.5665, 126.9780);
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isMapAvailable = true;
  bool _isMoving = false;

  // Fallback manual input controllers
  final _latController = TextEditingController(text: '37.5665');
  final _lngController = TextEditingController(text: '126.9780');
  final _manualAddressController = TextEditingController();

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // flutter_map은 순수 Flutter 렌더링 — SDK 실패 폴백 타이머 불필요
    _goToCurrentLocation(initial: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _manualAddressController.dispose();
    _mapController.dispose();
    _debounceTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation({bool initial = false}) async {
    try {
      await _locationService.requestPermission();
      final position = await _locationService.getCurrentPosition();
      final newPos = LatLng(position.latitude, position.longitude);

      setState(() {
        _centerPosition = newPos;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      try {
        _mapController.move(newPos, 16);
      } catch (_) {/* 맵 미렌더 상태면 무시 */}

      _reverseGeocode(newPos);
    } catch (e) {
      if (mounted && !initial) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('위치를 가져올 수 없습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onCenterChanged(LatLng center) {
    _centerPosition = center;
    if (!_isMoving) {
      setState(() => _isMoving = true);
    }

    // Debounce reverse geocoding
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _reverseGeocode(center);
      if (mounted) {
        setState(() => _isMoving = false);
      }
    });
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
          if (p.locality?.isNotEmpty == true) p.locality!,
          if (p.subLocality?.isNotEmpty == true) p.subLocality!,
          if (p.thoroughfare?.isNotEmpty == true) p.thoroughfare!,
          if (p.subThoroughfare?.isNotEmpty == true) p.subThoroughfare!,
        ];
        setState(() {
          _address = parts.isNotEmpty ? parts.join(' ') : '주소를 찾을 수 없습니다';
          _latController.text = position.latitude.toStringAsFixed(6);
          _lngController.text = position.longitude.toStringAsFixed(6);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = '주소 변환 실패 (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newPos = LatLng(loc.latitude, loc.longitude);
        setState(() => _centerPosition = newPos);
        try {
          _mapController.move(newPos, 16);
        } catch (_) {/* 맵 미렌더 상태면 무시 */}
        _reverseGeocode(newPos);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('검색 결과가 없습니다')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 검색에 실패했습니다')),
        );
      }
    }
  }

  void _confirm() {
    final result = LocationResult(
      latitude: _centerPosition.latitude,
      longitude: _centerPosition.longitude,
      address: _address.isNotEmpty ? _address : '위치 선택됨',
    );
    Navigator.of(context).pop(result);
  }

  void _confirmManual() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 좌표를 입력해주세요')),
      );
      return;
    }
    final result = LocationResult(
      latitude: lat,
      longitude: lng,
      address: _manualAddressController.text.trim().isNotEmpty
          ? _manualAddressController.text.trim()
          : '직접 입력 ($lat, $lng)',
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: _isMapAvailable ? _buildMapView() : _buildManualInput(),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Map View
  // ─────────────────────────────────────────────────────────
  Widget _buildMapView() {
    return Stack(
      children: [
        // OSM 지도 (flutter_map — 전 플랫폼 호환, 다크 타일)
        OsmMap(
          controller: _mapController,
          center: _centerPosition,
          zoom: 16,
          onPositionChanged: _onCenterChanged,
        ),

        // Center pin
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.translationValues(
                0,
                _isMoving ? -8 : 0,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 48,
                    color: AppColors.brandYellow,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: _isMoving ? 8 : 4,
                          spreadRadius: _isMoving ? 2 : 0,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Top bar: search + cancel
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Cancel button
                _CircleButton(
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                // Search field
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '장소 검색...',
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        filled: false,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchLocation,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Current location FAB
        Positioned(
          right: 16,
          bottom: 180,
          child: _CircleButton(
            icon: Icons.my_location,
            onTap: _goToCurrentLocation,
            size: 48,
          ),
        ),

        // Fallback to manual input button
        Positioned(
          right: 16,
          bottom: 236,
          child: _CircleButton(
            icon: Icons.edit_location_alt,
            onTap: () => setState(() => _isMapAvailable = false),
            size: 48,
          ),
        ),

        // Bottom address panel + confirm
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [AppShadows.modal],
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address
                Row(
                  children: [
                    const Icon(Icons.place, color: AppColors.brandYellow, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isLoadingAddress
                          ? Text(
                              '주소 검색 중...',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textMuted),
                            )
                          : Text(
                              _address.isNotEmpty ? _address : '지도를 움직여 위치를 선택하세요',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _address.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Coordinates
                Text(
                  '${_centerPosition.latitude.toStringAsFixed(6)}, ${_centerPosition.longitude.toStringAsFixed(6)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                // Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _address.isNotEmpty || !_isLoadingAddress
                        ? _confirm
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '이 위치 선택',
                      style: AppTextStyles.button.copyWith(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Manual Input Fallback (no API key / map unavailable)
  // ─────────────────────────────────────────────────────────
  Widget _buildManualInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Text(
                  '위치 직접 입력',
                  style: AppTextStyles.headingMd
                      .copyWith(color: AppColors.textPrimary),
                ),
                const Spacer(),
                if (_isMapAvailable)
                  TextButton.icon(
                    onPressed: () => setState(() => _isMapAvailable = true),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('지도'),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              '좌표 입력',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: '위도 (Latitude)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: '경도 (Longitude)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current location button
            OutlinedButton.icon(
              onPressed: _goToCurrentLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('현재 위치 가져오기'),
            ),
            const SizedBox(height: 24),

            Text(
              '주소 (선택사항)',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _manualAddressController,
              decoration: const InputDecoration(
                hintText: '예: 서울특별시 중구 세종대로 110',
              ),
            ),

            const Spacer(),

            // Confirm
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _confirmManual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '이 위치 선택',
                  style: AppTextStyles.button.copyWith(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular button used for map controls.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bgElevated.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black38,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: size * 0.5),
      ),
    );
  }
}
