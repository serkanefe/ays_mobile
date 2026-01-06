import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  final ApiService _apiService = ApiService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      if (response['user'] == null) {
        throw Exception('Kullanıcı bilgisi alınamadı');
      }
      
      _user = User.fromJson(response['user']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token'] ?? '');
      
      // Beni Hatırla işlemi
      if (rememberMe) {
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Giriş başarısız: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, String>?> loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');
      
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      debugPrint('Kayıtlı kimlik bilgileri yüklenirken hata: $e');
    }
    return null;
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
