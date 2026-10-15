// =============================================================================
// FILE: lib/features/search/presentation/widgets/map/index_map_widget.dart
// LAYER: Presentation Layer
// RESPONSIBILITY: Interactive OpenStreetMap with GPS Location & Radius Filtering.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class IndexMapWidget extends StatefulWidget {
  final List<dynamic> results;
  final Function(int id, String category)? onMarkerTap;
  final Function(LatLng location)? onLocationFound;
  final double? radiusKm;
  final Map<String, dynamic>? translations;

  const IndexMapWidget({
    super.key,
    required this.results,
    this.onMarkerTap,
    this.onLocationFound,
    this.radiusKm,
    this.translations,
  });

  @override
  State<IndexMapWidget> createState() => _IndexMapWidgetState();
}

class _IndexMapWidgetState extends State<IndexMapWidget> {
  bool _isExpanded = false;
  bool _isLocating = false;
  LatLng? _userLocation;
  final MapController _mapController = MapController();

  // ===========================================================================
  // МЕНЕДЖЕР ГЕОЛОКАЦИИ И ПРОВЕРКИ СИСТЕМНОГО GPS
  // ===========================================================================
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      // 1. Проверяем, включен ли GPS в системе смартфона
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showGpsDisabledDialog();
        setState(() => _isLocating = false);
        return;
      }

      // 2. Проверяем и запрашиваем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showToast("Доступ к геолокации отклонен");
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showToast("Геолокация заблокирована в настройках устройства");
        await Geolocator.openAppSettings();
        setState(() => _isLocating = false);
        return;
      }

      // 3. Получаем точные координаты
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = userLatLng;
        _isLocating = false;
      });

      // Перемещаем камеру карты на позицию пользователя
      _mapController.move(userLatLng, 13.0);

      // Уведомляем родительский виджет для поиска по радиусу
      if (widget.onLocationFound != null) {
        widget.onLocationFound!(userLatLng);
      }
    } catch (e) {
      debugPrint("[IndexMapWidget] Location Error: $e");
      _showToast("Не удалось определить местоположение");
      setState(() => _isLocating = false);
    }
  }

  void _showGpsDisabledDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Color(0xFFFF8A00)),
            SizedBox(width: 10),
            Text("GPS выключен", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          "Для поиска объектов поблизости необходимо включить геолокацию на устройстве.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("ОТМЕНА", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F2FF),
              foregroundColor: const Color(0xFF0F172A),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Geolocator.openLocationSettings();
            },
            child: const Text("ВКЛЮЧИТЬ GPS", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Фильтрация постов: наличие координат + попадание в радиус от пользователя
    final validPosts = widget.results.where((p) {
      if (p is! Map) return false;
      final double? lat = double.tryParse(p['lat']?.toString() ?? '');
      final double? lng = double.tryParse(p['lng']?.toString() ?? '');
      if (lat == null || lng == null) return false;

      // Если геолокация определена и задан радиус — фильтруем по дистанции
      if (_userLocation != null && widget.radiusKm != null && widget.radiusKm! > 0) {
        final double distanceInMeters = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          lat,
          lng,
        );
        final double distanceInKm = distanceInMeters / 1000.0;
        return distanceInKm <= widget.radiusKm!;
      }

      return true;
    }).toList();

    LatLng initialCenter = _userLocation ?? const LatLng(50.0412, 21.9991);
    if (_userLocation == null && validPosts.isNotEmpty) {
      final double? lat = double.tryParse(validPosts.first['lat'].toString());
      final double? lng = double.tryParse(validPosts.first['lng'].toString());
      if (lat != null && lng != null) {
        initialCenter = LatLng(lat, lng);
      }
    }

    final String toggleMapLabel = widget.translations?['toggle_map'] ??
        widget.translations?['map_index.toggle_map'] ??
        'Interactive map Articles';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              if (_isExpanded && _userLocation == null) {
                _getCurrentLocation();
              }
            },
            icon: const Icon(Icons.map_rounded, color: Color(0xFF0B0F19), size: 18),
            label: Text(
              '🗺️ ${toggleMapLabel.toUpperCase()} (${validPosts.length})',
              style: const TextStyle(
                color: Color(0xFF0B0F19),
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F2FF),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isExpanded ? 320 : 0,
          margin: EdgeInsets.only(top: _isExpanded ? 12 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00F2FF).withValues(alpha: 0.4), width: 1.5),
            boxShadow: _isExpanded
                ? [BoxShadow(color: const Color(0xFF00F2FF).withValues(alpha: 0.15), blurRadius: 12)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _isExpanded
                ? Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: initialCenter,
                          initialZoom: 10.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.findway.findway_mobile',
                          ),

                          // 1. Слой радиуса вокруг пользователя
                          if (_userLocation != null && widget.radiusKm != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _userLocation!,
                                  radius: widget.radiusKm! * 1000, // Перевод в метры
                                  useRadiusInMeter: true,
                                  color: const Color(0xFF00F2FF).withValues(alpha: 0.15),
                                  borderColor: const Color(0xFF00F2FF),
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),

                          // 2. Слой маркеров постов (только отфильтрованные)
                          MarkerLayer(
                            markers: [
                              ...validPosts.map((post) {
                                final double lat = double.parse(post['lat'].toString());
                                final double lng = double.parse(post['lng'].toString());
                                final LatLng pos = LatLng(lat, lng);

                                return Marker(
                                  point: pos,
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (widget.onMarkerTap != null) {
                                        final int id = int.parse(post['id'].toString());
                                        final String category = post['category']?.toString() ?? 'people';
                                        widget.onMarkerTap!(id, category);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF00F2FF), width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFFF8A00),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // 3. Маркер текущей позиции пользователя
                              if (_userLocation != null)
                                Marker(
                                  point: _userLocation!,
                                  width: 24,
                                  height: 24,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00F2FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00F2FF).withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Кнопка определения GPS поверх карты
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'index_map_gps_btn',
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: const Color(0xFF00F2FF),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFF00F2FF), width: 1),
                          ),
                          onPressed: _isLocating ? null : _getCurrentLocation,
                          child: _isLocating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00F2FF),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 20),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}