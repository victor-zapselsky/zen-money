class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final String type; // 'income' | 'expense'
  final bool isDefault;

  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'type': type,
    'is_default': isDefault ? 1 : 0,
  };

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
    id: m['id'] as int?,
    name: m['name'] as String,
    icon: m['icon'] as String,
    color: m['color'] as String,
    type: m['type'] as String,
    isDefault: (m['is_default'] as int) == 1,
  );

  CategoryModel copyWith({int? id, String? name, String? icon, String? color, String? type, bool? isDefault}) =>
    CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
}
