class AccountModel {
  final int id;
  final String name;
  final String type; // CASH or BANK
  final double balance;
  final bool isActive;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.isActive,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }
}
