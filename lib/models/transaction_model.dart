class TransactionModel {
  final int id;
  final int accountId;
  final int? relatedAccount;
  final String type; // INCOME / EXPENSE / TRANSFER
  final String? source;
  final int? relatedId;
  final double amount;
  final String? description;
  final bool isCanceled;
  final int? createdBy;
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.relatedAccount,
    required this.type,
    required this.source,
    required this.relatedId,
    required this.amount,
    required this.description,
    required this.isCanceled,
    required this.createdBy,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      accountId: json['account_id'] as int,
      relatedAccount: json['related_account'],
      type: json['type'] ?? '',
      source: json['source'],
      relatedId: json['related_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'],
      isCanceled: json['is_canceled'] ?? false,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
