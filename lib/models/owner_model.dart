class Owner {
  final int? id;
  final String fullName;
  final String email;
  final String? password;
  final String? phone;
  final String? identityNumber;  // TC
  final int? unitId;
  final String? unitName;  // Daire No
  final String? unitType;  // Mesken / İşyeri
  final double? shareRatio;  // Arsa payı
  final String ownerType;  // PERSON, COMPANY
  final String? role;  // Yönetici, Yönetici Yardımcısı, Denetci, Malik
  final String? tenantName;
  final String? tenantEmail;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Mali özet (isteğe bağlı)
  final double? totalRent;
  final double? totalPaid;
  final double? remainingDebt;

  Owner({
    this.id,
    required this.fullName,
    required this.email,
    this.password,
    this.phone,
    this.identityNumber,
    this.unitId,
    this.unitName,
    this.unitType,
    this.shareRatio,
    this.ownerType = 'PERSON',
    this.role,
    this.tenantName,
    this.tenantEmail,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.totalRent,
    this.totalPaid,
    this.remainingDebt,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      phone: json['phone'],
      identityNumber: json['identity_number'],
      unitId: json['unit_id'],
      unitName: json['unit_name'],
      unitType: json['unit_type'],
      shareRatio: json['share_ratio'] != null 
        ? double.tryParse(json['share_ratio'].toString())
        : null,
      ownerType: json['owner_type'] ?? 'PERSON',
      role: json['role'],
      tenantName: json['tenant_name'],
      tenantEmail: json['tenant_email'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
      totalRent: json['total_rent'] != null 
        ? double.tryParse(json['total_rent'].toString())
        : null,
      totalPaid: json['total_paid'] != null 
        ? double.tryParse(json['total_paid'].toString())
        : null,
      remainingDebt: json['remaining_debt'] != null 
        ? double.tryParse(json['remaining_debt'].toString())
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'identity_number': identityNumber,
      'unit_id': unitId,
      'unit_name': unitName,
      'unit_type': unitType,
      'share_ratio': shareRatio,
      'owner_type': ownerType,
      'role': role,
      'tenant_name': tenantName,
      'tenant_email': tenantEmail,
      'is_active': isActive,
      'total_rent': totalRent,
      'total_paid': totalPaid,
      'remaining_debt': remainingDebt,
    };
  }
}
