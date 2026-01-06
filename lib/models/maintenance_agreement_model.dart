class MaintenanceAgreement {
  final int id;
  final String name;

  MaintenanceAgreement({required this.id, required this.name});

  factory MaintenanceAgreement.fromJson(Map<String, dynamic> json) {
    return MaintenanceAgreement(
      id: json['id'] as int,
      name: json['name'] ?? '',
    );
  }
}
