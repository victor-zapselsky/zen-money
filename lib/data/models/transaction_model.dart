class TransactionModel {
  final int? id;
  final int accountId;
  final int categoryId;
  final double amount;
  final String type; // 'income' | 'expense'
  final DateTime date;
  final String? note;
  final String? accountName;
  final String? accountCurrency;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  const TransactionModel({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.accountName,
    this.accountCurrency,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  double get signedAmount => type == 'expense' ? -amount : amount;
  bool get isIncome => type == 'income';

  TransactionModel copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    double? amount,
    String? type,
    DateTime? date,
    String? note,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        date: date ?? this.date,
        note: note ?? this.note,
        accountName: accountName,
        accountCurrency: accountCurrency,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        categoryColor: categoryColor,
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'account_id': accountId,
    'category_id': categoryId,
    'amount': amount,
    'type': type,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> m) => TransactionModel(
    id: m['id'] as int?,
    accountId: m['account_id'] as int,
    categoryId: m['category_id'] as int,
    amount: (m['amount'] as num).toDouble(),
    type: m['type'] as String,
    date: DateTime.parse(m['date'] as String),
    note: m['note'] as String?,
    accountName: m['account_name'] as String?,
    accountCurrency: m['account_currency'] as String?,
    categoryName: m['category_name'] as String?,
    categoryIcon: m['category_icon'] as String?,
    categoryColor: m['category_color'] as String?,
  );
}
