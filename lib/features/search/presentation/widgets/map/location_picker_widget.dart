
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final Map<String, dynamic> translations;
  final Function(double lat, double lng) onLocationSelected;
  final Function(String address) onAddressChanged;

  const LocationPickerWidget({
    super.key,
    this.initialLat = 50.0412, // Дефолтный центр
    this.initialLng = 21.9991,
    required this.translations,
    required this.onLocationSelected,
    required this.onAddressChanged,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late MapController _mapController;
  late LatLng _currentPosition;
  final TextEditingController _addressController = TextEditingController();

  Timer? _debounce;
  final Dio _geocodingDio = Dio();
  bool _isSearching = false;

  final Color _cardDark = const Color(0xFF1E293B);
  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentCyan = const Color(0xFF00F2FF);
  final Color _accentOrange = const Color(0xFFFF8A00);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPosition = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  String _tr(String key, String fallback) {
    return (widget.translations[key] ?? widget.translations['map_picker.$key'] ?? fallback).toString();
  }

  // ===========================================================================
  // АКТИВНЫЙ ГЕОКОДИНГ (NOMINATIM / OPENSTREETMAP)
  // ===========================================================================
  void _onAddressTextChanged(String text) {
    // 1. Передаем введенный текст в форму
    widget.onAddressChanged(text);

    // 2. Сбрасываем предыдущий таймер
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = text.trim();
    if (query.length < 3) return;

    // 3. Задержка 600 мс (Debounce) перед запросом к геокодеру
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;

      setState(() => _isSearching = true);

      try {
        final response = await _geocodingDio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': query,
            'format': 'json',
            'limit': 1,
          },
          options: Options(
            headers: {
              'User-Agent': 'FindWayMobileApp/1.0', // Требование Nominatim API
            },
          ),
        );

        if (response.data is List && (response.data as List).isNotEmpty) {
          final firstResult = response.data[0];
          final double? searchedLat = double.tryParse(firstResult['lat'].toString());
          final double? searchedLng = double.tryParse(firstResult['lon'].toString());

          if (searchedLat != null && searchedLng != null && mounted) {
            final newPos = LatLng(searchedLat, searchedLng);
            
            setState(() {
              _currentPosition = newPos;
            });

            // Центрируем карту и обновляем маркер
            _mapController.move(newPos, 15.0);
            
            // Передаем точные координаты в родительскую форму
            widget.onLocationSelected(searchedLat, searchedLng);
          }
        }
      } catch (_) {
        // Игнорируем ошибки сети при поиске
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentCyan.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок карточки
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _bgDark,
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: _accentCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _tr('location_label', 'Вкажіть місце на карті').toUpperCase(),
                    style: TextStyle(
                      color: _accentCyan,
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Область интерактивной карты
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 14.0,
                      onTap: (_, latLng) {
                        setState(() => _currentPosition = latLng);
                        widget.onLocationSelected(latLng.latitude, latLng.longitude);
                      },
                      onPositionChanged: (pos, hasGesture) {
                        if (hasGesture && pos.center != null) {
                          _currentPosition = pos.center!;
                          widget.onLocationSelected(_currentPosition.latitude, _currentPosition.longitude);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.findway.findway_mobile',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              color: _accentOrange,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Подсказка поверх карты
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _tr('picker_hint', 'Клацніть на карті або введіть адресу нижче'),
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Инпут текстового поиска адреса с анимацией загрузки
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextFormField(
                controller: _addressController,
                onChanged: _onAddressTextChanged,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: _tr('adress_placeholder', 'Введіть адресу або орієнтир'),
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: Icon(Icons.edit_location_alt, color: _accentCyan, size: 18),
                  suffixIcon: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accentCyan,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: _bgDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}