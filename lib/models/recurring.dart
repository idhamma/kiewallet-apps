class Recurring {
  final int id;
  final String name;
  final num amount;
  final String account;
  final String category;
  final String periodType;
  final int dayOfMonth;
  final String dayOfWeek;

  Recurring({
    required this.id,
    required this.name,
    required this.amount,
    required this.account,
    required this.category,
    required this.periodType,
    this.dayOfMonth = 1,
    this.dayOfWeek = 'Senin',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'account': account,
        'category': category,
        'periodType': periodType,
        'dayOfMonth': dayOfMonth,
        'dayOfWeek': dayOfWeek,
      };

  factory Recurring.fromMap(Map<String, dynamic> m) => Recurring(
        id: (m['id'] as num).toInt(),
        name: m['name'] as String? ?? '',
        amount: (m['amount'] as num?) ?? 0,
        account: m['account'] as String? ?? '',
        category: m['category'] as String? ?? 'Tagihan',
        periodType: m['periodType'] as String? ?? 'monthly',
        dayOfMonth: (m['dayOfMonth'] as num?)?.toInt() ?? 1,
        dayOfWeek: m['dayOfWeek'] as String? ?? 'Senin',
      );

  Recurring copyWith({
    int? id,
    String? name,
    num? amount,
    String? account,
    String? category,
    String? periodType,
    int? dayOfMonth,
    String? dayOfWeek,
  }) =>
      Recurring(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        account: account ?? this.account,
        category: category ?? this.category,
        periodType: periodType ?? this.periodType,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      );
}
