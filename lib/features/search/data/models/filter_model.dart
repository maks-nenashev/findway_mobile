class FilterOption {
  final int id;      
  final String label; 

  FilterOption({required this.id, required this.label});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      // Приводим к int, даже если Rails пришлет строку (защита)
      id: int.parse(json['id'].toString()),
      label: json['label'] as String? ?? '',
    );
  }
}

class FilterModel {
  final String id;    
  final String type;  
  final String label; 
  final List<FilterOption>? options; 

  FilterModel({
    required this.id,
    required this.type,
    required this.label,
    this.options,
  });

  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      label: json['label'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}