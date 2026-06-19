class GoalModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String icon;
  final DateTime? deadline;
  final DateTime createdAt;

  const GoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.icon,
    this.deadline,
    required this.createdAt,
  });

  double get percent => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0, 1) : 0;
  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);
  bool get isCompleted => savedAmount >= targetAmount;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'target_amount': targetAmount,
    'saved_amount': savedAmount,
    'icon': icon,
    'deadline': deadline?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory GoalModel.fromMap(Map<String, dynamic> m) => GoalModel(
    id: m['id'] as int?,
    name: m['name'] as String,
    targetAmount: (m['target_amount'] as num).toDouble(),
    savedAmount: (m['saved_amount'] as num).toDouble(),
    icon: m['icon'] as String,
    deadline: m['deadline'] != null ? DateTime.parse(m['deadline'] as String) : null,
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  GoalModel copyWith({
    int? id, String? name, double? targetAmount, double? savedAmount,
    String? icon, DateTime? deadline, DateTime? createdAt,
  }) => GoalModel(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    savedAmount: savedAmount ?? this.savedAmount,
    icon: icon ?? this.icon,
    deadline: deadline ?? this.deadline,
    createdAt: createdAt ?? this.createdAt,
  );
}
