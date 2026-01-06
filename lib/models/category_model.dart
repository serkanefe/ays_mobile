class Category {
  final int? id;
  final String name;
  final String categoryType; // INCOME or EXPENSE

  Category({
    this.id,
    required this.name,
    required this.categoryType,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      categoryType: json['category_type'] ?? 'EXPENSE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_type': categoryType,
    };
  }

  bool get isIncome => categoryType == 'INCOME';
  bool get isExpense => categoryType == 'EXPENSE';
}
