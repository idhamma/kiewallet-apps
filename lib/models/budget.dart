class CustomBudget {
  final int id;
  final String name;
  final num limit;
  final List<String> categories;
  final String desc;

  CustomBudget({
    required this.id,
    required this.name,
    required this.limit,
    required this.categories,
    this.desc = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'limit': limit,
        'categories': categories,
        'desc': desc,
      };

  factory CustomBudget.fromMap(Map<String, dynamic> m) => CustomBudget(
        id: (m['id'] as num).toInt(),
        name: m['name'] as String? ?? '',
        limit: (m['limit'] as num?) ?? 0,
        categories: List<String>.from(m['categories'] as List? ?? const []),
        desc: m['desc'] as String? ?? '',
      );

  CustomBudget copyWith({
    int? id,
    String? name,
    num? limit,
    List<String>? categories,
    String? desc,
  }) =>
      CustomBudget(
        id: id ?? this.id,
        name: name ?? this.name,
        limit: limit ?? this.limit,
        categories: categories ?? this.categories,
        desc: desc ?? this.desc,
      );
}
