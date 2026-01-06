class RentModel {
  final int id;
  final int ownerId;
  final String? ownerName;
  final int month;
  final int year;
  final double amount;
  final DateTime? dueDate;
  final String status; // UNPAID, PAID
  final double? lateFee;
  final int? categoryId;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RentModel({
    required this.id,
    required this.ownerId,
    this.ownerName,
    required this.month,
    required this.year,
    required this.amount,
    this.dueDate,
    required this.status,
    this.lateFee,
    this.categoryId,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory RentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? v) => v == null ? null : DateTime.tryParse(v);
    return RentModel(
      id: json['id'] as int,
      ownerId: json['owner_id'] ?? 0,
      ownerName: json['owner_name'],
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: parseDate(json['due_date']),
      status: (json['status'] ?? 'UNPAID').toString().toUpperCase(),
      lateFee: json['late_fee'] != null ? (json['late_fee'] as num).toDouble() : null,
      categoryId: json['category_id'],
      description: json['description'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

