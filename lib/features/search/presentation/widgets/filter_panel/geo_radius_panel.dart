// =============================================================================
// FILE: lib/features/search/presentation/widgets/filter_panel/geo_radius_panel.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: PostGIS geolocation search panel with radius slider and GPS trigger.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';

class GeoRadiusPanel extends StatelessWidget {
  final double radiusKm;
  final double? searchLat;
  final double? searchLng;
  final Map<String, dynamic> trans;
  final Function(double newRadius) onRadiusChanged;
  final Function(double lat, double lng) onLocationSet;

  const GeoRadiusPanel({
    required this.radiusKm,
    required this.searchLat,
    required this.searchLng,
    required this.trans,
    required this.onRadiusChanged,
    required this.onLocationSet,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF0F172A);
    const Color orangeAccent = Color(0xFFFF8A00);

    final String titleText = trans['radius_search'] ??
        trans['map_picker.radius_search'] ??
        trans['shared.map_picker.radius_search'] ??
        trans['filters.radius_search'] ??
        'Пошук у радіусі (PostGIS)';

    final String radiusLabelText = trans['radius_label'] ??
        trans['map_picker.radius_label'] ??
        trans['shared.map_picker.radius_label'] ??
        trans['filters.radius_label'] ??
        'Радіус покриття';

    final String kmUnit = trans['km'] ??
        trans['map_picker.km'] ??
        trans['shared.map_picker.km'] ??
        trans['filters.km'] ??
        'км';

    final String btnText = trans['detect_my_location'] ??
        trans['map_picker.detect_my_location'] ??
        trans['shared.map_picker.detect_my_location'] ??
        trans['filters.detect_my_location'] ??
        'Визначити мою геолокацію';

    final String centerPrefix = trans['search_center'] ??
        trans['map_picker.search_center'] ??
        trans['shared.map_picker.search_center'] ??
        trans['filters.search_center'] ??
        'Центр';

    final String noCenterText = trans['no_search_center'] ??
        trans['map_picker.no_search_center'] ??
        trans['shared.map_picker.no_search_center'] ??
        trans['filters.no_search_center'] ??
        'Центр не вибрано';

    final String geoStatusText = (searchLat != null && searchLng != null)
        ? '$centerPrefix: ${searchLat!.toStringAsFixed(3)}, ${searchLng!.toStringAsFixed(3)}'
        : noCenterText;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orangeAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText.toUpperCase(),
            style: const TextStyle(
              color: orangeAccent,
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                radiusLabelText,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
              ),
              Text(
                '${radiusKm.round()} $kmUnit',
                style: const TextStyle(
                  color: orangeAccent,
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (radiusKm > 1) {
                    final newRad = radiusKm - 1;
                    onRadiusChanged(newRad);
                    context.read<SearchBloc>().add(UpdateFilterValue(filterId: 'radius_km', value: newRad.round()));
                  }
                },
                icon: const Icon(Icons.remove_circle_outline, color: orangeAccent, size: 20),
              ),
              Expanded(
                child: Slider(
                  value: radiusKm,
                  min: 1,
                  max: 200,
                  divisions: 199,
                  activeColor: orangeAccent,
                  inactiveColor: Colors.white12,
                  onChanged: (val) {
                    onRadiusChanged(val);
                    context.read<SearchBloc>().add(UpdateFilterValue(filterId: 'radius_km', value: val.round()));
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  if (radiusKm < 200) {
                    final newRad = radiusKm + 1;
                    onRadiusChanged(newRad);
                    context.read<SearchBloc>().add(UpdateFilterValue(filterId: 'radius_km', value: newRad.round()));
                  }
                },
                icon: const Icon(Icons.add_circle_outline, color: orangeAccent, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                const double defaultLat = 50.0412;
                const double defaultLng = 21.9991;
                onLocationSet(defaultLat, defaultLng);

                final bloc = context.read<SearchBloc>();
                bloc.add(const UpdateFilterValue(filterId: 'search_lat', value: defaultLat));
                bloc.add(const UpdateFilterValue(filterId: 'search_lng', value: defaultLng));
                bloc.add(UpdateFilterValue(filterId: 'radius_km', value: radiusKm.round()));
                bloc.add(const PerformSearch());
              },
              icon: const Icon(Icons.my_location, size: 16),
              label: Text(btnText.toUpperCase(), style: const TextStyle(fontFamily: 'Orbitron', fontSize: 10)),
              style: OutlinedButton.styleFrom(
                foregroundColor: orangeAccent,
                side: const BorderSide(color: orangeAccent),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            geoStatusText,
            style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Monospace'),
          ),
        ],
      ),
    );
  }
}