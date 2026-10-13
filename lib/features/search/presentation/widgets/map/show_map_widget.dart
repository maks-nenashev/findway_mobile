import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ShowMapWidget extends StatelessWidget {
  final double lat;
  final double lng;
  final String title;
  final String address;
  final Map<String, dynamic>? translations;

  const ShowMapWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.title,
    required this.address,
    this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng location = LatLng(lat, lng);

    final String locationHeader = translations?['location_header'] ??
        translations?['map_show.location_header'] ??
        translations?['shared.map_show.location_header'] ??
        'Місце на карті';

    final String addressLabel = translations?['address_label'] ??
        translations?['map_show.address_label'] ??
        translations?['shared.map_show.address_label'] ??
        'Адреса / орієнтир:';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFF8A00), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    locationHeader,
                    style: const TextStyle(
                      color: Color(0xFF00F2FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),

            // Map Area
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: location,
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.findway.findway_mobile',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00F2FF), width: 2),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFFF8A00),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer Address
            if (address.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin, color: Color(0xFF00F2FF), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$addressLabel ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}