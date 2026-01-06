class Unit {
  final int? id;
  final String blockName;
  final String unitNumber;
  final int? ownerId;
  final String? ownerName;
  final double? shareRatio;
  final bool isActive;
  final DateTime? createdAt;

  Unit({
    this.id,
    required this.blockName,
    required this.unitNumber,
    this.ownerId,
    this.ownerName,
    this.shareRatio,
    this.isActive = true,
    this.createdAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      blockName: json['block_name'] ?? '',
      unitNumber: json['unit_number'] ?? '',
      ownerId: json['owner_id'],
      ownerName: json['owner_name'],
      shareRatio: json['share_ratio']?.toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'block_name': blockName,
      'unit_number': unitNumber,
      'owner_id': ownerId,
      'share_ratio': shareRatio,
      'is_active': isActive,
    };
  }

  String get fullAddress => '$blockName - $unitNumber';
}
