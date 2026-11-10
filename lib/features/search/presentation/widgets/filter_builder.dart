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
      key: ValueKey('list_$currentCategory'),
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
      initialValue: valueExists ? (currentValue as int?) : null,
      hint: Text(filter.label),
      decoration: InputDecoration(
        // Показываем верхнюю подпись ТОЛЬКО если значение выбрано
        floatingLabelBehavior: valueExists 
            ? FloatingLabelBehavior.always 
            : FloatingLabelBehavior.never,
        label: Transform.translate(
          offset: const Offset(0, -10),
          child: Text(filter.label),
        ),
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: (val) => onFilterChanged(filter.id, val),
    );
  }

  Widget _buildTextField(FilterModel filter, Key key) {
    final rawVal = selectedValues[filter.id]?.toString();
    final bool hasValue = rawVal != null && rawVal.trim().isNotEmpty;

    return TextFormField(
      key: key,
      initialValue: rawVal,
      decoration: InputDecoration(
        // Показываем верхнюю подпись ТОЛЬКО если текст введен
        floatingLabelBehavior: hasValue 
            ? FloatingLabelBehavior.always 
            : FloatingLabelBehavior.never,
        hintText: filter.label,
        label: Transform.translate(
          offset: const Offset(0, -10),
          child: Text(filter.label),
        ),
        border: const OutlineInputBorder(),
      ),
      onChanged: (val) => onFilterChanged(filter.id, val),
    );
  }
}