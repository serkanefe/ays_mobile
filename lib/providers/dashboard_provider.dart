import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _chartData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get stats => _stats;
  Map<String, dynamic>? get chartData => _chartData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _apiService.getDashboardStats();
      _chartData = await _apiService.getChartData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Dashboard verileri yüklenemedi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReportsSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _apiService.getReportsSummary();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Rapor özeti yüklenemedi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
