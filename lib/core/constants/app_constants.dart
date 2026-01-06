class AppConstants {
  // API Base URL
  static const String apiBaseUrl = 'http://192.168.1.8:5000/api';
  
  // SharedPreferences Keys
  static const String tokenKey = 'token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userRoleKey = 'user_role';
  static const String rememberMeKey = 'remember_me';
  
  // User Roles
  static const String roleAdmin = 'ADMIN';
  static const String roleManager = 'MANAGER';
  static const String roleOwner = 'OWNER';
  
  // Payment Status
  static const String statusPaid = 'PAID';
  static const String statusUnpaid = 'UNPAID';
  static const String statusPartial = 'PARTIAL';
  
  // Account Types
  static const String accountCash = 'KASA';
  static const String accountBank = 'BANKA';
  
  // Date Format
  static const String dateFormat = 'dd.MM.yyyy';
  static const String dateTimeFormat = 'dd.MM.yyyy HH:mm';
  
  // Months
  static const List<String> months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Animations
  static const Duration animationDuration = Duration(milliseconds: 300);
}
