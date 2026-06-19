class AccountModel {
  final int? id;
  final String name;
  final String type; // 'debit' | 'credit' | 'cash' | 'savings'
  final double balance;
  final String color;
  final String icon;
  final String? currency;     // null = use global setting
  final double exchangeRate;  // 1 unit of account currency = exchangeRate units of main currency
  final DateTime createdAt;

  const AccountModel({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
    this.currency,
    this.exchangeRate = 1.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'type': type,
    'balance': balance,
    'color': color,
    'icon': icon,
    if (currency != null) 'currency': currency,
    'exchange_rate': exchangeRate,
    'created_at': createdAt.toIso8601String(),
  };

  factory AccountModel.fromMap(Map<String, dynamic> m) => AccountModel(
    id: m['id'] as int?,
    name: m['name'] as String,
    type: m['type'] as String,
    balance: (m['balance'] as num).toDouble(),
    color: m['color'] as String,
    icon: m['icon'] as String,
    currency: m['currency'] as String?,
    exchangeRate: (m['exchange_rate'] as num? ?? 1.0).toDouble(),
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  AccountModel copyWith({
    int? id, String? name, String? type, double? balance,
    String? color, String? icon, String? currency, double? exchangeRate,
    DateTime? createdAt,
  }) => AccountModel(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    balance: balance ?? this.balance,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    currency: currency ?? this.currency,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    createdAt: createdAt ?? this.createdAt,
  );

  String get typeLabel {
    switch (type) {
      case 'debit':   return 'Дебетовая';
      case 'credit':  return 'Кредитная';
      case 'cash':    return 'Кошелёк';
      case 'savings': return 'Накопительный';
      default:        return type;
    }
  }
}
