class ExpenseModel {
  final int id;
  final String name;
  final int categoryId;
  final String? categoryName;
  final DateTime? date;
  final double amount;
  final String? payee;
  final int accountId;
  final String? accountName;
  final String? accountType;
  final String? receiptNo;
  final int? maintenanceAgreementId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryName,
    this.date,
    required this.amount,
    this.payee,
    required this.accountId,
    this.accountName,
    this.accountType,
    this.receiptNo,
    this.maintenanceAgreementId,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? v) => v == null ? null : DateTime.tryParse(v);

    return ExpenseModel(
      id: json['id'] as int,
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'],
      date: parseDate(json['date'] ?? json['expense_date']),
      amount: (json['amount'] ?? 0).toDouble(),
      payee: json['payee'],
      accountId: json['account_id'] ?? 0,
      accountName: json['account_name'],
      accountType: json['account_type'],
      receiptNo: json['receipt_no'],
      maintenanceAgreementId: json['maintenance_agreement_id'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}
