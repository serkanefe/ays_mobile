import 'package:flutter/foundation.dart';
import '../models/unit_model.dart';
import '../services/api_service.dart';

class UnitProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Unit> _units = [];
  bool _isLoading = false;
  String? _error;

  List<Unit> get units => _units;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUnits() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getUnits();
      _units = data.map<Unit>((json) => Unit.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Daireler yüklenemedi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUnit({
    required String blockName,
    required String unitNumber,
    int? ownerId,
    double? shareRatio,
  }) async {
    try {
      await _apiService.createUnit(
        blockName: blockName,
        unitNumber: unitNumber,
        ownerId: ownerId,
        shareRatio: shareRatio,
      );
      await fetchUnits();
      return true;
    } catch (e) {
      _error = 'Daire eklenemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUnit(int unitId, Map<String, dynamic> unitData) async {
    try {
      await _apiService.updateUnit(
        unitId,
        blockName: unitData['block_name'],
        unitNumber: unitData['unit_number'],
        ownerId: unitData['owner_id'],
        shareRatio: unitData['share_ratio'],
        isActive: unitData['is_active'],
      );
      await fetchUnits();
      return true;
    } catch (e) {
      _error = 'Daire güncellenemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUnit(int unitId) async {
    try {
      await _apiService.deleteUnit(unitId);
      await fetchUnits();
      return true;
    } catch (e) {
      _error = 'Daire silinemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
