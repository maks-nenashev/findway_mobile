// =============================================================================
// FILE: lib/features/search/presentation/widgets/map/index_map_widget.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class IndexMapWidget extends StatefulWidget {
  final List<dynamic> results;
  final Function(int id, String category)? onMarkerTap;
  final Map<String, dynamic>? translations;

  const IndexMapWidget({
    super.key,
    required this.results,
    this.onMarkerTap,
    this.translations,
  });

  @override
  State<IndexMapWidget> createState() => _IndexMapWidgetState();
}

class _IndexMapWidgetState extends State<IndexMapWidget> {
  bool _isExpanded = false;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final validPosts = widget.results.where((p) {
      if (p is! Map) return false;
      return p['lat'] != null && p['lng'] != null;
    }).toList();

    LatLng initialCenter = const LatLng(50.0412, 21.9991);
    if (validPosts.isNotEmpty) {
      final double? lat = double.tryParse(validPosts.first['lat'].toString());
      final double? lng = double.tryParse(validPosts.first['lng'].toString());
      if (lat != null && lng != null) {
        initialCenter = LatLng(lat, lng);
      }
    }

    // lib/features/search/presentation/widgets/map/index_map_widget.dart
    print("ДОСТУПНЫЕ КЛЮЧИ КАРТЫ: ${widget.translations?.keys.where((k) => k.contains('map')).toList()}");
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
          height: _isExpanded ? 300 : 0,
          margin: EdgeInsets.only(top: _isExpanded ? 12 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00F2FF).withOpacity(0.4), width: 1.5),
            boxShadow: _isExpanded
                ? [BoxShadow(color: const Color(0xFF00F2FF).withOpacity(0.15), blurRadius: 12)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _isExpanded
                ? FlutterMap(
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
                      MarkerLayer(
                        markers: validPosts.map((post) {
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
                        }).toList(),
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