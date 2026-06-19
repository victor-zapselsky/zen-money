class BudgetModel {
  final int? id;
  final int categoryId;
  final double limitAmount;
  final double spentAmount;
  final int month;
  final int year;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  const BudgetModel({
    this.id,
    required this.categoryId,
    required this.limitAmount,
    this.spentAmount = 0,
    required this.month,
    required this.year,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  double get percent => limitAmount > 0 ? (spentAmount / limitAmount).clamp(0, 1) : 0;
  bool get isOver => spentAmount >= limitAmount;
  bool get isNear => percent >= 0.9 && !isOver;
  double get remaining => (limitAmount - spentAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category_id': categoryId,
    'limit_amount': limitAmount,
    'month': month,
    'year': year,
  };

  factory BudgetModel.fromMap(Map<String, dynamic> m) => BudgetModel(
    id: m['id'] as int?,
    categoryId: m['category_id'] as int,
    limitAmount: (m['limit_amount'] as num).toDouble(),
    spentAmount: (m['spent_amount'] as num? ?? 0).toDouble(),
    month: m['month'] as int,
    year: m['year'] as int,
    categoryName: m['category_name'] as String?,
    categoryIcon: m['category_icon'] as String?,
    categoryColor: m['category_color'] as String?,
  );
}
