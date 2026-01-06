import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../models/category_model.dart' as models;
import '../services/api_service.dart';

class SettingsProvider with ChangeNotifier {
  Settings? _settings;
  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  
  final ApiService _apiService = ApiService();

  Settings? get settings => _settings;
  List<models.Category> get categories => _categories;
  List<models.Category> get incomeCategories => _categories.where((c) => c.isIncome).toList();
  List<models.Category> get expenseCategories => _categories.where((c) => c.isExpense).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getSettings();
      _settings = Settings.fromJson(data);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ayarlar yüklenirken hata: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings({
    String? siteName,
    String? siteAddress,
    String? city,
    String? taxNumber,
    String? taxOffice,
    String? smtpServer,
    int? smtpPort,
    String? mailAddress,
    String? smtpPassword,
    int? rentDueDay,
    bool? adminPaysRent,
    bool? applyLateFee,
    double? lateFeeRate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'site_name': siteName ?? _settings?.siteName,
        'site_address': siteAddress ?? _settings?.siteAddress,
        'city': city ?? _settings?.city,
        'tax_number': taxNumber ?? _settings?.taxNumber,
        'tax_office': taxOffice ?? _settings?.taxOffice,
        'smtp_server': smtpServer ?? _settings?.smtpServer,
        'smtp_port': smtpPort ?? _settings?.smtpPort,
        'mail_address': mailAddress ?? _settings?.mailAddress,
        'smtp_password': smtpPassword ?? _settings?.smtpPassword,
        'rent_due_day': rentDueDay ?? _settings?.rentDueDay,
        'admin_pays_rent': adminPaysRent ?? _settings?.adminPaysRent,
        'apply_late_fee': applyLateFee ?? _settings?.applyLateFee,
        'late_fee_rate': lateFeeRate ?? _settings?.lateFeeRate,
      };
      
      final result = await _apiService.saveSettings(data);
      if (result['success'] ?? false) {
        await loadSettings();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw Exception('Ayarlar kaydedilemedi');
    } catch (e) {
      _error = 'Ayarlar kaydedilirken hata: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getCategories();
      _categories = List<models.Category>.from(
        data.map((cat) => models.Category.fromJson(cat as Map<String, dynamic>))
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Kategoriler yüklenirken hata: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    required String categoryType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createCategory(
        name: name,
        categoryType: categoryType,
      );
      
      final category = models.Category.fromJson(result);
      _categories.add(category);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Kategori eklenirken hata: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteCategory(categoryId);
      _categories.removeWhere((cat) => cat.id == categoryId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Kategori silinirken hata: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
