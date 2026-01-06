class Settings {
  final int? id;
  final String? siteName;
  final String? siteAddress;
  final String? city;
  final String? taxNumber;
  final String? taxOffice;
  final String? smtpServer;
  final int? smtpPort;
  final String? mailAddress;
  final String? smtpPassword;
  final int? rentDueDay;
  final bool? adminPaysRent;
  final bool? applyLateFee;
  final double? lateFeeRate;

  Settings({
    this.id,
    this.siteName,
    this.siteAddress,
    this.city,
    this.taxNumber,
    this.taxOffice,
    this.smtpServer,
    this.smtpPort,
    this.mailAddress,
    this.smtpPassword,
    this.rentDueDay,
    this.adminPaysRent,
    this.applyLateFee,
    this.lateFeeRate,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      id: json['id'],
      siteName: json['site_name'] ?? '',
      siteAddress: json['site_address'] ?? '',
      city: json['city'] ?? '',
      taxNumber: json['tax_number'] ?? '',
      taxOffice: json['tax_office'] ?? '',
      smtpServer: json['smtp_server'] ?? '',
      smtpPort: json['smtp_port'],
      mailAddress: json['mail_address'] ?? '',
      smtpPassword: json['smtp_password'] ?? '',
      rentDueDay: json['rent_due_day'] ?? 1,
      adminPaysRent: json['admin_pays_rent'] ?? false,
      applyLateFee: json['apply_late_fee'] ?? false,
      lateFeeRate: json['late_fee_rate'] ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_name': siteName,
      'site_address': siteAddress,
      'city': city,
      'tax_number': taxNumber,
      'tax_office': taxOffice,
      'smtp_server': smtpServer,
      'smtp_port': smtpPort,
      'mail_address': mailAddress,
      'smtp_password': smtpPassword,
      'rent_due_day': rentDueDay,
      'admin_pays_rent': adminPaysRent,
      'apply_late_fee': applyLateFee,
      'late_fee_rate': lateFeeRate,
    };
  }
}
