class Debt {
  final int id;
  final String person;
  final String type;
  final num amount;
  final String account;
  final String dueDate;
  final String status;

  Debt({
    required this.id,
    required this.person,
    required this.type,
    required this.amount,
    required this.account,
    required this.dueDate,
    this.status = 'unpaid',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'person': person,
        'type': type,
        'amount': amount,
        'account': account,
        'dueDate': dueDate,
        'status': status,
      };

  factory Debt.fromMap(Map<String, dynamic> m) => Debt(
        id: (m['id'] as num).toInt(),
        person: m['person'] as String,
        type: m['type'] as String,
        amount: (m['amount'] as num?) ?? 0,
        account: m['account'] as String? ?? '',
        dueDate: m['dueDate'] as String? ?? '',
        status: m['status'] as String? ?? 'unpaid',
      );

  Debt copyWith({
    int? id,
    String? person,
    String? type,
    num? amount,
    String? account,
    String? dueDate,
    String? status,
  }) =>
      Debt(
        id: id ?? this.id,
        person: person ?? this.person,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        account: account ?? this.account,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
      );
}
