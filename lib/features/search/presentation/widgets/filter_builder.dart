import 'package:flutter/material.dart';
import '../../data/models/filter_model.dart';

class FilterBuilder extends StatelessWidget {
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final String currentCategory;
  final Function(String filterId, dynamic value) onFilterChanged;

  const FilterBuilder({
    super.key,
    required this.filters,
    required this.selectedValues,
    required this.currentCategory,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('list_$currentCategory'), // Принудительный ребилд при смене таба
      children: filters.map((filter) {
        final widgetKey = ValueKey('${currentCategory}_${filter.id}');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: filter.type == 'dropdown' 
            ? _buildDropdown(filter, widgetKey)
            : _buildTextField(filter, widgetKey),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown(FilterModel filter, Key key) {
    final items = filter.options?.map((option) {
      return DropdownMenuItem<int>(value: option.id, child: Text(option.label));
    }).toList() ?? [];

    final currentValue = selectedValues[filter.id];
    final bool valueExists = items.any((item) => item.value == currentValue);

    return DropdownButtonFormField<int>(
      key: key,
      value: valueExists ? (currentValue as int?) : null,
      decoration: InputDecoration(labelText: filter.label, border: const OutlineInputBorder()),
      items: items,
      onChanged: (val) => onFilterChanged(filter.id, val),
    );
  }

  Widget _buildTextField(FilterModel filter, Key key) {
    return TextFormField(
      key: key,
      initialValue: selectedValues[filter.id]?.toString(),
      decoration: InputDecoration(labelText: filter.label, border: const OutlineInputBorder()),
      onChanged: (val) => onFilterChanged(filter.id, val),
    );
  }
}