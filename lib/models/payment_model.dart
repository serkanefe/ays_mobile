class PaymentModel {
  final int id;
  final int rentId;
  final int ownerId;
  final String? ownerName;
  final int accountId;
  final String? accountName;
  final double amount;
  final double? lateFeeAmount;
  final DateTime? paymentDate;
  final String? referenceNumber;
  final bool isCancelled;
  final DateTime? cancellationDate;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.rentId,
    required this.ownerId,
    this.ownerName,
    required this.accountId,
    this.accountName,
    required this.amount,
    this.lateFeeAmount,
    this.paymentDate,
    this.referenceNumber,
    required this.isCancelled,
    this.cancellationDate,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? v) => v == null ? null : DateTime.tryParse(v);
    return PaymentModel(
      id: json['id'] as int,
      rentId: json['rent_id'] ?? 0,
      ownerId: json['owner_id'] ?? 0,
      ownerName: json['owner_name'],
      accountId: json['account_id'] ?? 0,
      accountName: json['account_name'],
      amount: (json['amount'] ?? 0).toDouble(),
      lateFeeAmount: json['late_fee_amount'] != null ? (json['late_fee_amount'] as num).toDouble() : null,
      paymentDate: parseDate(json['payment_date']),
      referenceNumber: json['reference_number'],
      isCancelled: json['is_cancelled'] ?? false,
      cancellationDate: parseDate(json['cancellation_date']),
      cancellationReason: json['cancellation_reason'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rent_id': rentId,
    'owner_id': ownerId,
    'owner_name': ownerName,
    'account_id': accountId,
    'account_name': accountName,
    'amount': amount,
    'late_fee_amount': lateFeeAmount,
    'payment_date': paymentDate?.toIso8601String(),
    'reference_number': referenceNumber,
    'is_cancelled': isCancelled,
    'cancellation_date': cancellationDate?.toIso8601String(),
    'cancellation_reason': cancellationReason,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
