import 'package:flutter/foundation.dart';
import '../models/owner_model.dart';
import '../services/api_service.dart';

class OwnerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Owner> _owners = [];
  bool _isLoading = false;
  String? _error;

  List<Owner> get owners => _owners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOwners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getOwners();
      _owners = data.map<Owner>((json) => Owner.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Malikler yüklenemedi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOwner(Map<String, dynamic> ownerData) async {
    try {
      final result = await _apiService.createOwner(
        fullName: ownerData['full_name'],
        email: ownerData['email'],
        password: ownerData['password'],
        phone: ownerData['phone'],
        identityNumber: ownerData['identity_number'],
        unitName: ownerData['unit_name'],
        unitType: ownerData['unit_type'],
        shareRatio: ownerData['share_ratio'],
        ownerType: ownerData['owner_type'] ?? 'PERSON',
        role: ownerData['role'],
        tenantName: ownerData['tenant_name'],
        tenantEmail: ownerData['tenant_email'],
      );
      
      // Eğer mock modda ise, döndürülen sahibi bilgisini listeye doğrudan ekle
      if (result['success'] == true && result['owner'] != null) {
        final newOwner = Owner.fromJson(result['owner']);
        _owners.add(newOwner);
        _error = null;
        notifyListeners();
      } else {
        // Yoksa fetch ile güncelleştir
        await fetchOwners();
      }
      return true;
    } catch (e) {
      _error = 'Malik eklenemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOwner(int ownerId, Map<String, dynamic> ownerData) async {
    try {
      final result = await _apiService.updateOwner(
        ownerId,
        fullName: ownerData['full_name'],
        email: ownerData['email'],
        password: ownerData['password'],
        phone: ownerData['phone'],
        identityNumber: ownerData['identity_number'],
        unitName: ownerData['unit_name'],
        unitType: ownerData['unit_type'],
        shareRatio: ownerData['share_ratio'],
        ownerType: ownerData['owner_type'],
        role: ownerData['role'],
        tenantName: ownerData['tenant_name'],
        tenantEmail: ownerData['tenant_email'],
      );
      
      // Eğer mock modda ise, güncellenmiş sahibi bilgisini listede güncelle
      if (result['success'] == true && result['owner'] != null) {
        final updatedOwner = Owner.fromJson(result['owner']);
        final index = _owners.indexWhere((o) => o.id == ownerId);
        if (index != -1) {
          _owners[index] = updatedOwner;
        }
        _error = null;
        notifyListeners();
      } else {
        // Yoksa fetch ile güncelleştir
        await fetchOwners();
      }
      return true;
    } catch (e) {
      _error = 'Malik güncellenemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOwner(int ownerId) async {
    try {
      final result = await _apiService.deleteOwner(ownerId);
      
      // Eğer mock modda ise, sahibi hemen listeden kaldır
      if (result['success'] == true) {
        _owners.removeWhere((o) => o.id == ownerId);
        _error = null;
        notifyListeners();
      } else {
        // Yoksa fetch ile güncelleştir
        await fetchOwners();
      }
      return true;
    } catch (e) {
      _error = 'Malik silinemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
