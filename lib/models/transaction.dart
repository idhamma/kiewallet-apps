class Tx {
  final int id;
  final String type;
  final String date;
  final String? time;
  final num amount;
  final String account;
  final String category;
  final String note;

  Tx({
    required this.id,
    required this.type,
    required this.date,
    this.time,
    required this.amount,
    required this.account,
    this.category = '',
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'date': date,
        if (time != null) 'time': time,
        'amount': amount,
        'account': account,
        'category': category,
        'note': note,
      };

  factory Tx.fromMap(Map<String, dynamic> m) => Tx(
        id: (m['id'] as num).toInt(),
        type: m['type'] as String,
        date: m['date'] as String,
        time: m['time'] as String?,
        amount: (m['amount'] as num?) ?? 0,
        account: m['account'] as String? ?? '',
        category: m['category'] as String? ?? '',
        note: m['note'] as String? ?? '',
      );

  Tx copyWith({
    int? id,
    String? type,
    String? date,
    String? time,
    num? amount,
    String? account,
    String? category,
    String? note,
  }) =>
      Tx(
        id: id ?? this.id,
        type: type ?? this.type,
        date: date ?? this.date,
        time: time ?? this.time,
        amount: amount ?? this.amount,
        account: account ?? this.account,
        category: category ?? this.category,
        note: note ?? this.note,
      );

  bool get isInflow =>
      type == 'income' ||
      type == 'utang_in' ||
      type == 'piutang_in' ||
      type == 'transfer_in';
}
