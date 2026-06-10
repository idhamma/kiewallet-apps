class PortfolioItem {
  final int id;
  final String type;
  final String name;
  final num amount;
  final num buyPrice;
  final num? currentPrice;
  final String account;
  final bool isDeduct;
  final String marketSymbol;

  PortfolioItem({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.buyPrice,
    this.currentPrice,
    this.account = '',
    this.isDeduct = false,
    this.marketSymbol = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'name': name,
        'amount': amount,
        'buyPrice': buyPrice,
        if (currentPrice != null) 'currentPrice': currentPrice,
        'account': account,
        'isDeduct': isDeduct,
        'marketSymbol': marketSymbol,
      };

  factory PortfolioItem.fromMap(Map<String, dynamic> m) => PortfolioItem(
        id: (m['id'] as num).toInt(),
        type: m['type'] as String,
        name: m['name'] as String? ?? '',
        amount: (m['amount'] as num?) ?? 0,
        buyPrice: (m['buyPrice'] as num?) ?? 0,
        currentPrice: m['currentPrice'] as num?,
        account: m['account'] as String? ?? '',
        isDeduct: m['isDeduct'] as bool? ?? false,
        marketSymbol: m['marketSymbol'] as String? ?? '',
      );

  PortfolioItem copyWith({
    int? id,
    String? type,
    String? name,
    num? amount,
    num? buyPrice,
    num? currentPrice,
    String? account,
    bool? isDeduct,
    String? marketSymbol,
  }) =>
      PortfolioItem(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        buyPrice: buyPrice ?? this.buyPrice,
        currentPrice: currentPrice ?? this.currentPrice,
        account: account ?? this.account,
        isDeduct: isDeduct ?? this.isDeduct,
        marketSymbol: marketSymbol ?? this.marketSymbol,
      );
}
