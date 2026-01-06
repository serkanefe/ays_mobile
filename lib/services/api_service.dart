import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // HARDCODED - Test için PC IP'si
  static const String defaultBaseUrl = 'http://192.168.1.8:5000/api';
  static const bool useMockData = false; // Real API kullan
  
  late final Dio _dio;
  late String _baseUrl;

  ApiService() {
    _initializeDio();
  }

  Future<void> _initializeDio() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_url') ?? defaultBaseUrl;
    
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('[API] ${options.method} ${options.path}');
        return handler.next(options);
      },
      onError: (error, handler) {
        print('[API ERROR] ${error.type}: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  // ==================== AUTH ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (useMockData) {
      // Demo veri - test amaçlı
      if (email == 'manager1@example.com' && password == 'Test123') {
        return {
          'success': true,
          'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 1,
            'full_name': 'Yönetici',
            'email': 'manager1@example.com',
            'role': 'MANAGER',
            'is_active': true,
          }
        };
      } else if (email == 'admin@example.com' && password == 'Admin123') {
        return {
          'success': true,
          'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 2,
            'full_name': 'Admin Kullanıcı',
            'email': 'admin@example.com',
            'role': 'ADMIN',
            'is_active': true,
          }
        };
      } else {
        throw Exception('Geçersiz e-posta veya şifre');
      }
    }
    
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post('/auth/forgot-password', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final response = await _dio.post('/auth/change-password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    return response.data;
  }

  // ==================== USER ====================
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/user/profile');
    return response.data;
  }

  // ==================== DASHBOARD ====================
  Future<Map<String, dynamic>> getDashboardStats() async {
    if (useMockData) {
      return {
        'total_owners': 45,
        'total_units': 120,
        'total_revenue': 125000.50,
        'pending_payments': 8500.00,
        'total_expenses': 45000.00,
        'cash_balance': 65500.50,
        'bank_balance': 235000.00,
      };
    }
    
    final response = await _dio.get('/dashboard/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> getChartData() async {
    final response = await _dio.get('/dashboard/chart-data');
    return response.data;
  }

  Future<List<dynamic>> getUnpaidRents() async {
    final response = await _dio.get('/dashboard/unpaid-rents');
    return response.data['rents'];
  }

  // ==================== RENTS ====================
  Future<List<dynamic>> getRents() async {
    final response = await _dio.get('/rents');
    return response.data['rents'] ?? response.data;
  }

  Future<Map<String, dynamic>> createRent({
    required int userId,
    required int month,
    required int year,
    required double amount,
    String? dueDate,
    String? description,
  }) async {
    final response = await _dio.post('/rents', data: {
      'user_id': userId,
      'month': month,
      'year': year,
      'amount': amount,
      'due_date': dueDate,
      'description': description,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> bulkCreateRent({
    required int month,
    required int year,
    required double amount,
    String? dueDate,
  }) async {
    final response = await _dio.post('/rents/bulk', data: {
      'month': month,
      'year': year,
      'amount': amount,
      'due_date': dueDate,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateRent(
    int rentId, {
    double? amount,
    String? dueDate,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (amount != null) data['amount'] = amount;
    if (dueDate != null) data['due_date'] = dueDate;
    if (description != null) data['description'] = description;
    final response = await _dio.put('/rents/$rentId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteRent(int rentId) async {
    final response = await _dio.delete('/rents/$rentId');
    return response.data;
  }

  // ==================== PAYMENTS ====================
  Future<List<dynamic>> getPayments() async {
    final response = await _dio.get('/payments');
    return response.data['payments'];
  }

  Future<Map<String, dynamic>> createPayment({
    required int rentId,
    required int accountId,
    required double amount,
    double lateFeeAmount = 0,
    String? paymentDate,
    String? referenceNumber,
  }) async {
    final response = await _dio.post('/payments', data: {
      'rent_id': rentId,
      'account_id': accountId,
      'amount': amount,
      'late_fee_amount': lateFeeAmount,
      'payment_date': paymentDate,
      'reference_number': referenceNumber,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> cancelPayment(int paymentId, {String? reason}) async {
    final response = await _dio.put('/payments/$paymentId/cancel', data: {
      'cancellation_reason': reason,
    });
    return response.data;
  }

  // ==================== EXPENSES ====================
  Future<List<dynamic>> getExpenses() async {
    final response = await _dio.get('/expenses');
    return response.data['expenses'];
  }

  Future<Map<String, dynamic>> createExpense({
    required String name,
    required int categoryId,
    required double amount,
    required int accountId,
    String? payee,
    String? receiptNo,
    String? date,
  }) async {
    final response = await _dio.post('/expenses', data: {
      'name': name,
      'category_id': categoryId,
      'amount': amount,
      'account_id': accountId,
      'payee': payee,
      'receipt_no': receiptNo,
      'date': date,
    });
    return response.data;
  }

  // ==================== ACCOUNTS ====================
  Future<List<dynamic>> getAccounts() async {
    final response = await _dio.get('/accounts');
    return response.data['accounts'];
  }

  Future<Map<String, dynamic>> createAccount({
    required String accountName,
    required String accountType,
    required String accountNumber,
    String? iban,
    required double openingBalance,
    String? openingDate,
  }) async {
    final response = await _dio.post('/accounts', data: {
      'account_name': accountName,
      'account_type': accountType,
      'account_number': accountNumber,
      'iban': iban,
      'opening_balance': openingBalance,
      'opening_date': openingDate,
    });
    return response.data;
  }

  // ==================== TRANSFERS ====================
  Future<List<dynamic>> getTransfers() async {
    final response = await _dio.get('/transfers');
    return response.data['transfers'];
  }

  Future<Map<String, dynamic>> createTransfer({
    required int senderAccountId,
    required int receiverAccountId,
    required double amount,
    String? referenceNumber,
    String? transactionDate,
  }) async {
    final response = await _dio.post('/transfers', data: {
      'sender_account_id': senderAccountId,
      'receiver_account_id': receiverAccountId,
      'amount': amount,
      'reference_number': referenceNumber,
      'transaction_date': transactionDate,
    });
    return response.data;
  }

  // ==================== MAINTENANCE AGREEMENTS ====================
  Future<List<dynamic>> getMaintenanceAgreements() async {
    final response = await _dio.get('/maintenance-agreements');
    return response.data['agreements'];
  }

  Future<Map<String, dynamic>> createMaintenanceAgreement({
    required String name,
    required int categoryId,
    String? companyName,
    String? contactPerson,
    String? phone,
    required double amount,
    required String period,
    required String startDate,
    String? endDate,
  }) async {
    final response = await _dio.post('/maintenance-agreements', data: {
      'name': name,
      'category_id': categoryId,
      'company_name': companyName,
      'contact_person': contactPerson,
      'phone': phone,
      'amount': amount,
      'period': period,
      'start_date': startDate,
      'end_date': endDate,
    });
    return response.data;
  }

  // ==================== OWNERS ====================
  Future<List<dynamic>> getOwners() async {
    if (useMockData) {
      return [
        {
          'id': 1,
          'full_name': 'Ahmet Yılmaz',
          'email': 'ahmet@example.com',
          'password': 'Ahmet123',
          'phone': '05551234567',
          'identity_number': '12345678901',
          'unit_name': 'A Blok - 101',
          'unit_type': 'Mesken',
          'share_ratio': 8.5,
          'owner_type': 'PERSON',
          'role': 'Malik',
          'tenant_name': 'Mehmet Demir',
          'tenant_email': 'mehmet@example.com',
          'is_active': true,
          'total_rent': 25000.00,
          'total_paid': 22000.00,
          'remaining_debt': 3000.00,
        },
        {
          'id': 2,
          'full_name': 'Ayşe Kaya',
          'email': 'ayse@example.com',
          'password': 'Ayse123',
          'phone': '05559876543',
          'identity_number': '12345678902',
          'unit_name': 'A Blok - 102',
          'unit_type': 'Mesken',
          'share_ratio': 8.5,
          'owner_type': 'PERSON',
          'role': 'Malik',
          'tenant_name': 'Fatma Yıldız',
          'tenant_email': 'fatma@example.com',
          'is_active': true,
          'total_rent': 25000.00,
          'total_paid': 25000.00,
          'remaining_debt': 0.0,
        },
        {
          'id': 3,
          'full_name': 'Teknoloji Ltd. Şti.',
          'email': 'info@teknoloji.com',
          'password': 'Teknoloji123',
          'phone': '02121234567',
          'identity_number': '9876543210',
          'unit_name': 'B Blok - 201',
          'unit_type': 'İşyeri',
          'share_ratio': 9.0,
          'owner_type': 'COMPANY',
          'role': 'Malik',
          'tenant_name': 'İbrahim Karan',
          'tenant_email': 'ibrahim@example.com',
          'is_active': true,
          'total_rent': 30000.00,
          'total_paid': 15000.00,
          'remaining_debt': 15000.00,
        },
      ];
    }
    
    final response = await _dio.get('/owners');
    return response.data['owners'];
  }

  Future<Map<String, dynamic>> getOwnerDetail(int ownerId) async {
    if (useMockData) {
      final allOwners = await getOwners();
      final owner = allOwners.firstWhere(
        (o) => o['id'] == ownerId,
        orElse: () => {'id': ownerId, 'full_name': 'Bulunamadı'},
      );
      return {'owner': owner};
    }
    
    final response = await _dio.get('/owners/$ownerId');
    return response.data['owner'];
  }

  Future<Map<String, dynamic>> getOwnerFinancialSummary(int ownerId) async {
    if (useMockData) {
      return {
        'owner_id': ownerId,
        'total_rent': 25000.00,
        'total_paid': 22000.00,
        'remaining_debt': 3000.00,
        'currency': 'TRY',
      };
    }
    
    final response = await _dio.get('/owners/$ownerId/financial-summary');
    return response.data;
  }

  Future<Map<String, dynamic>> createOwner({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? identityNumber,
    int? unitId,
    String? unitName,
    String? unitType,
    double? shareRatio,
    String ownerType = 'PERSON',
    String role = 'Malik',
    String? tenantName,
    String? tenantEmail,
  }) async {
    final data = {
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
    };
    
    if (useMockData) {
      return {
        'success': true,
        'owner': {
          'id': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ...data,
          'is_active': true,
          'total_rent': 0.0,
          'total_paid': 0.0,
          'remaining_debt': 0.0,
        }
      };
    }
    
    final response = await _dio.post('/owners', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateOwner(
    int ownerId, {
    String? fullName,
    String? email,
    String? password,
    String? phone,
    String? identityNumber,
    int? unitId,
    String? unitName,
    String? unitType,
    double? shareRatio,
    String? ownerType,
    String? role,
    String? tenantName,
    String? tenantEmail,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (phone != null) data['phone'] = phone;
    if (identityNumber != null) data['identity_number'] = identityNumber;
    if (unitId != null) data['unit_id'] = unitId;
    if (unitName != null) data['unit_name'] = unitName;
    if (unitType != null) data['unit_type'] = unitType;
    if (shareRatio != null) data['share_ratio'] = shareRatio;
    if (ownerType != null) data['owner_type'] = ownerType;
    if (role != null) data['role'] = role;
    if (tenantName != null) data['tenant_name'] = tenantName;
    if (tenantEmail != null) data['tenant_email'] = tenantEmail;
    if (isActive != null) data['is_active'] = isActive;
    
    if (useMockData) {
      return {
        'success': true,
        'owner': {'id': ownerId, ...data}
      };
    }
    
    final response = await _dio.put('/owners/$ownerId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteOwner(int ownerId) async {
    if (useMockData) {
      return {
        'success': true,
        'message': 'Malik başarıyla silindi',
      };
    }
    
    final response = await _dio.delete('/owners/$ownerId');
    return response.data;
  }
  // ==================== UPDATE & DELETE OPERATIONS ====================
  
  // Expense UPDATE & DELETE
  Future<Map<String, dynamic>> updateExpense(
    int expenseId, {
    int? categoryId,
    double? amount,
    int? accountId,
    String? date,
    String? payee,
    String? name,
    String? receiptNo,
  }) async {
    final data = <String, dynamic>{};
    if (categoryId != null) data['category_id'] = categoryId;
    if (amount != null) data['amount'] = amount;
    if (accountId != null) data['account_id'] = accountId;
    if (date != null) data['date'] = date;
    if (payee != null) data['payee'] = payee;
    if (name != null) data['name'] = name;
    if (receiptNo != null) data['receipt_no'] = receiptNo;
    
    final response = await _dio.put('/expenses/$expenseId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteExpense(int expenseId) async {
    final response = await _dio.delete('/expenses/$expenseId');
    return response.data;
  }

  // Account UPDATE & DELETE
  Future<Map<String, dynamic>> updateAccount(
    int accountId, {
    String? accountName,
    String? iban,
    String? accountNumber,
  }) async {
    final data = <String, dynamic>{};
    if (accountName != null) data['account_name'] = accountName;
    if (iban != null) data['iban'] = iban;
    if (accountNumber != null) data['account_number'] = accountNumber;
    
    final response = await _dio.put('/accounts/$accountId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteAccount(int accountId) async {
    final response = await _dio.delete('/accounts/$accountId');
    return response.data;
  }

  // ==================== REPORTS ====================
  Future<List<dynamic>> getApartmentListReport() async {
    final response = await _dio.get('/reports/apartment-list');
    return response.data['apartments'];
  }

  Future<Map<String, dynamic>> getBalanceReport() async {
    final response = await _dio.get('/reports/balance');
    return response.data;
  }

  Future<Map<String, dynamic>> getDebtReport() async {
    final response = await _dio.get('/reports/debt');
    return response.data;
  }

  // ==================== HEALTH ====================
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/health');
    return response.data;
  }

  // ==================== UNITS (Daire/Blok) ====================
  Future<List<dynamic>> getUnits() async {
    if (useMockData) {
      return [
        {
          'id': 1,
          'block_name': 'A Blok',
          'unit_number': '101',
          'owner_id': 1,
          'share_ratio': 8.5,
        },
        {
          'id': 2,
          'block_name': 'A Blok',
          'unit_number': '102',
          'owner_id': 2,
          'share_ratio': 8.5,
        },
        {
          'id': 3,
          'block_name': 'B Blok',
          'unit_number': '201',
          'owner_id': 3,
          'share_ratio': 9.0,
        },
      ];
    }
    
    final response = await _dio.get('/units');
    return response.data['units'];
  }

  Future<Map<String, dynamic>> getUnitDetail(int unitId) async {
    final response = await _dio.get('/units/$unitId');
    return response.data['unit'];
  }

  Future<Map<String, dynamic>> createUnit({
    required String blockName,
    required String unitNumber,
    int? ownerId,
    double? shareRatio,
  }) async {
    final response = await _dio.post('/units', data: {
      'block_name': blockName,
      'unit_number': unitNumber,
      'owner_id': ownerId,
      'share_ratio': shareRatio,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateUnit(
    int unitId, {
    String? blockName,
    String? unitNumber,
    int? ownerId,
    double? shareRatio,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (blockName != null) data['block_name'] = blockName;
    if (unitNumber != null) data['unit_number'] = unitNumber;
    if (ownerId != null) data['owner_id'] = ownerId;
    if (shareRatio != null) data['share_ratio'] = shareRatio;
    if (isActive != null) data['is_active'] = isActive;
    
    final response = await _dio.put('/units/$unitId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteUnit(int unitId) async {
    final response = await _dio.delete('/units/$unitId');
    return response.data;
  }

  // ==================== ANNOUNCEMENTS (Duyurular) ====================
  Future<List<dynamic>> getAnnouncements() async {    if (useMockData) {
      return [
        {
          'id': 1,
          'title': 'Demirbaş Saymanı',
          'content': 'Apartmanın demirbaş saymanı 15 Ocak\'ta yapılacaktır.',
          'is_pinned': true,
          'created_by': 'Yönetici',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'title': 'Su Kaçağı Onarımı',
          'content': '3. kattaki su kaçağı onarımı tamamlanmıştır.',
          'is_pinned': false,
          'created_by': 'Yönetici',
          'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        },
      ];
    }
        final response = await _dio.get('/announcements');
    return response.data['announcements'];
  }

  Future<Map<String, dynamic>> getAnnouncementDetail(int announcementId) async {
    final response = await _dio.get('/announcements/$announcementId');
    return response.data['announcement'];
  }

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    final response = await _dio.post('/announcements', data: {
      'title': title,
      'content': content,
      'is_pinned': isPinned,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateAnnouncement(
    int announcementId, {
    String? title,
    String? content,
    bool? isPinned,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (isPinned != null) data['is_pinned'] = isPinned;
    if (isActive != null) data['is_active'] = isActive;
    
    final response = await _dio.put('/announcements/$announcementId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteAnnouncement(int announcementId) async {
    final response = await _dio.delete('/announcements/$announcementId');
    return response.data;
  }

  // ==================== YEAR-END (Yıl Sonu İşlemleri) ====================
  Future<Map<String, dynamic>> closeYear(int year) async {
    final response = await _dio.post('/year-end/close', data: {
      'year': year,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getYearEndSummary(int year) async {
    final response = await _dio.get('/year-end/summary/$year');
    return response.data;
  }

  // ==================== REPORTS SUMMARY ====================
  Future<Map<String, dynamic>> getReportsSummary() async {
    final response = await _dio.get('/reports/summary');
    return response.data;
  }

  Future<Map<String, dynamic>> getChartReport() async {
    final response = await _dio.get('/reports/chart');
    return response.data;
  }

  // ==================== SETTINGS ====================
  Future<Map<String, dynamic>> getSettings() async {
    final response = await _dio.get('/settings');
    return response.data;
  }

  Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> data) async {
    final response = await _dio.post('/settings', data: data);
    return response.data;
  }

  // ==================== CATEGORIES ====================
  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get('/categories');
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String categoryType,
  }) async {
    final response = await _dio.post('/categories', data: {
      'name': name,
      'category_type': categoryType,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    final response = await _dio.delete('/categories/$categoryId');
    return response.data;
  }

  // ==================== KASA / BANKA ====================
  Future<List<dynamic>> getCashBankAccounts({bool? isActive}) async {
    final response = await _dio.get('/accounts', queryParameters: {
      if (isActive != null) 'is_active': isActive.toString(),
    });
    return response.data['accounts'] ?? [];
  }

  Future<Map<String, dynamic>> createCashBankAccount({
    required String name,
    required String type,
    double openingBalance = 0,
  }) async {
    final response = await _dio.post('/accounts', data: {
      'name': name,
      'type': type,
      'balance': openingBalance,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateCashBankAccount({
    required int id,
    String? name,
    String? type,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (type != null) data['type'] = type;
    if (isActive != null) data['is_active'] = isActive;
    final response = await _dio.put('/accounts/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deactivateCashBankAccount(int id) async {
    final response = await _dio.delete('/accounts/$id');
    return response.data;
  }

  Future<List<dynamic>> getCashBankTransactions({
    int? accountId,
    String? type,
    String? source,
    bool? isCanceled,
  }) async {
    final response = await _dio.get('/transactions', queryParameters: {
      if (accountId != null) 'account_id': accountId,
      if (type != null) 'type': type,
      if (source != null) 'source': source,
      if (isCanceled != null) 'is_canceled': isCanceled.toString(),
    });
    return response.data['transactions'] ?? [];
  }

  Future<Map<String, dynamic>> createCashBankIncome({
    required int accountId,
    required double amount,
    String? description,
    String? source,
    int? createdBy,
  }) async {
    final response = await _dio.post('/transactions/income', data: {
      'account_id': accountId,
      'amount': amount,
      'description': description,
      'source': source,
      'created_by': createdBy,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createCashBankExpense({
    required int accountId,
    required double amount,
    String? description,
    String? source,
    int? createdBy,
  }) async {
    final response = await _dio.post('/transactions/expense', data: {
      'account_id': accountId,
      'amount': amount,
      'description': description,
      'source': source,
      'created_by': createdBy,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createCashBankTransfer({
    required int sourceAccountId,
    required int targetAccountId,
    required double amount,
    String? description,
    int? createdBy,
  }) async {
    final response = await _dio.post('/transactions/transfer', data: {
      'source_account_id': sourceAccountId,
      'target_account_id': targetAccountId,
      'amount': amount,
      'description': description,
      'created_by': createdBy,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> cancelTransaction(int txId) async {
    final response = await _dio.delete('/transactions/$txId');
    return response.data;
  }

  // ==================== BACKUP ====================
  Future<String> getBackup() async {
    final response = await _dio.get(
      '/backup/download',
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );
    
    // Web platformu için - mobil cihazlarda bu method çalışmaz
    throw UnimplementedError('Backup download web platformu için tasarlanmıştır');
  }

  // API URL'sini güncelle ve kaydet
  Future<void> setApiUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', newUrl);
    _baseUrl = newUrl;
    
    // Dio'yu yeni URL ile yeniden başlat
    _dio = Dio(BaseOptions(
      baseUrl: newUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _setupInterceptors();
  }

  // Mevcut API URL'sini getir
  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_url') ?? defaultBaseUrl;
  }

  // Default URL'ye sıfırla
  Future<void> resetApiUrl() async {
    await setApiUrl(defaultBaseUrl);
  }
}
