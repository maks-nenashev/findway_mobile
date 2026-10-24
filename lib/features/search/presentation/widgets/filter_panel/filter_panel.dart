// =============================================================================
// FILE: lib/features/search/presentation/widgets/filter_panel/filter_panel.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Main filter dashboard combining category tabs, FilterBuilder,
//                 and expandable sub-panels for ID specs and geolocation.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_state.dart';
import 'package:findway_mobile/features/search/presentation/widgets/filter_builder.dart';
import 'package:findway_mobile/features/search/presentation/widgets/filter_panel/animal_id_panel.dart';
import 'package:findway_mobile/features/search/presentation/widgets/filter_panel/thing_id_panel.dart';
import 'package:findway_mobile/features/search/presentation/widgets/filter_panel/geo_radius_panel.dart';

class FilterPanel extends StatefulWidget {
  final SearchState state;
  final Map<String, dynamic> translations;
  final String currentLocale;
  final dynamic filters;
  final Map<String, dynamic> selectedFilterValues;
  final String activeCategory;
  final Function(String cat) onCategoryChanged;

  final TextEditingController chipController;
  final TextEditingController passportController;
  final TextEditingController insuranceController;
  final Map<String, TextEditingController> thingControllers;

  final double radiusKm;
  final double? searchLat;
  final double? searchLng;
  final Function(double rad) onRadiusChanged;
  final Function(double lat, double lng) onLocationSet;
  final VoidCallback onResetGeoAndControllers;

  const FilterPanel({
    required this.state,
    required this.translations,
    required this.currentLocale,
    required this.filters,
    required this.selectedFilterValues,
    required this.activeCategory,
    required this.onCategoryChanged,
    required this.chipController,
    required this.passportController,
    required this.insuranceController,
    required this.thingControllers,
    required this.radiusKm,
    required this.searchLat,
    required this.searchLng,
    required this.onRadiusChanged,
    required this.onLocationSet,
    required this.onResetGeoAndControllers,
    super.key,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  bool _isAdvancedIdOpen = false;
  bool _isGeoPanelOpen = false;

  String? _getSelectedSubCategoryLabel(dynamic filters, Map<String, dynamic> selectedValues) {
    if (filters == null) return null;

    dynamic selectedId;
    selectedValues.forEach((k, v) {
      if ((k.contains('phone_id') || k.contains('cat_id') || k.contains('sub_category')) && v != null) {
        selectedId = v;
      }
    });

    if (selectedId == null) return null;

    if (filters is List) {
      for (final f in filters) {
        if (f.options != null) {
          for (final opt in f.options) {
            if (opt.id.toString() == selectedId.toString()) {
              return opt.label;
            }
          }
        }
      }
    }
    return null;
  }

  int _getFieldsCountForCategory(String? label) {
    return ThingIdPanel.getFieldsForCategoryLabel(label).length;
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF1E293B);
    const Color neonBlue = Color(0xFF00F2FF);
    final bool isAnimalCategory = widget.activeCategory == 'animals';
    final bool isThingCategory = widget.activeCategory == 'things';
    final bool hasIdPanel = isAnimalCategory || isThingCategory;

    final String? selectedSubCategoryLabel = _getSelectedSubCategoryLabel(
      widget.filters,
      widget.selectedFilterValues,
    );
    final int fieldsCount = _getFieldsCountForCategory(selectedSubCategoryLabel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkSlate,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: darkSlate, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryButtons(context, widget.activeCategory, widget.translations, widget.currentLocale),
            const SizedBox(height: 20),
            _buildSearchField(context, widget.translations),
            const SizedBox(height: 16),
            if (widget.filters != null) ...[
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 10),
                    floatingLabelStyle: const TextStyle(color: neonBlue, fontWeight: FontWeight.bold, fontSize: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: darkSlate),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: neonBlue, width: 2),
                    ),
                  ),
                ),
                child: FilterBuilder(
                  filters: widget.filters,
                  selectedValues: widget.selectedFilterValues,
                  currentCategory: widget.activeCategory,
                  onFilterChanged: (id, val) =>
                      context.read<SearchBloc>().add(UpdateFilterValue(filterId: id, value: val)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                if (hasIdPanel) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isAdvancedIdOpen = !_isAdvancedIdOpen),
                      icon: const Icon(Icons.security, size: 16),
                      label: Text(
                        fieldsCount > 0 ? 'ID ($fieldsCount)' : 'ID',
                        style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00F2FF),
                        side: const BorderSide(color: Color(0xFF00F2FF)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _isGeoPanelOpen = !_isGeoPanelOpen),
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('Geo', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A00),
                      side: const BorderSide(color: Color(0xFFFF8A00)),
                    ),
                  ),
                ),
              ],
            ),
            if (isAnimalCategory && _isAdvancedIdOpen)
              AnimalIdPanel(
                chipController: widget.chipController,
                passportController: widget.passportController,
                insuranceController: widget.insuranceController,
                trans: widget.translations,
              ),
            if (isThingCategory && _isAdvancedIdOpen)
              ThingIdPanel(
                controllers: widget.thingControllers,
                trans: widget.translations,
                subCategoryLabel: selectedSubCategoryLabel,
              ),
            if (_isGeoPanelOpen)
              GeoRadiusPanel(
                radiusKm: widget.radiusKm,
                searchLat: widget.searchLat,
                searchLng: widget.searchLng,
                trans: widget.translations,
                onRadiusChanged: widget.onRadiusChanged,
                onLocationSet: widget.onLocationSet,
              ),
            const SizedBox(height: 16),
            if (widget.filters != null)
              _buildApplyFiltersButton(context, widget.translations),
            if (widget.state is SearchSuccess)
              _buildResetFiltersButton(context, widget.currentLocale, widget.activeCategory, widget.translations),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, Map<String, dynamic> translations) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: translations['plac_title'] ?? 'Пошук...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: ElevatedButton(
              onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
              child: Text(translations['find'] ?? 'FIND', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryButtons(
    BuildContext context,
    String activeCategory,
    Map<String, dynamic> translations,
    String currentLocale,
  ) {
    return Row(
      children: [
        _categoryTab(context, 'people', translations['button_article'] ?? 'Люди', const Color(0xFF00F2FF), activeCategory == 'people', currentLocale),
        const SizedBox(width: 8),
        _categoryTab(context, 'animals', translations['button_sense'] ?? 'Тварини', const Color(0xFFFF8A00), activeCategory == 'animals', currentLocale),
        const SizedBox(width: 8),
        _categoryTab(context, 'things', translations['button_thing'] ?? 'Речі', const Color(0xFF2ECC71), activeCategory == 'things', currentLocale),
      ],
    );
  }

  Widget _categoryTab(
    BuildContext context,
    String cat,
    String label,
    Color color,
    bool isActive,
    String locale,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isAdvancedIdOpen = false;
          });
          widget.onCategoryChanged(cat);
          context.read<SearchBloc>().add(LoadFilters(category: cat, locale: locale));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B), width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyFiltersButton(BuildContext context, Map<String, dynamic> translations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
        icon: const Icon(Icons.filter_list),
        label: Text(translations['filter_button'] ?? "Застосувати фильтри"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A00).withValues(alpha: 0.1),
          foregroundColor: const Color(0xFFFF8A00),
          side: const BorderSide(color: Color(0xFFFF8A00)),
        ),
      ),
    );
  }

  Widget _buildResetFiltersButton(
    BuildContext context,
    String currentLocale,
    String activeCategory,
    Map<String, dynamic> translations,
  ) {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _isAdvancedIdOpen = false;
          _isGeoPanelOpen = false;
        });
        widget.onResetGeoAndControllers();
        context.read<SearchBloc>().add(LoadFilters(category: activeCategory, locale: currentLocale));
      },
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(translations['last'] ?? translations['reset_filters'] ?? "Скинути фильтри"),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00F2FF)),
    );
  }
}