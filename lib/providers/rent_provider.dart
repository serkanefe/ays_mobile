import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/rent_model.dart';
import '../models/payment_model.dart';
import '../models/account_model.dart';
import '../models/owner_model.dart';
import '../services/api_service.dart';

class RentProvider with ChangeNotifier {
  RentProvider({required this.userRole, Set<int>? closedYears})
      : closedYears = closedYears ?? {};

  final String? userRole; // MANAGER / ASSISTANT_MANAGER / INSPECTOR / OWNER
  final Set<int> closedYears;

  final ApiService _api = ApiService();

  List<RentModel> rents = [];
  List<PaymentModel> payments = [];
  List<AccountModel> accounts = [];
  List<Owner> owners = [];

  bool isLoading = false;
  String? error;

  // Filters
  int? filterOwnerId;
  int? filterMonth;
  int? filterYear = DateTime.now().year;
  String? filterStatus; // UNPAID, PAID

  bool get canView {
    final r = userRole?.toUpperCase() ?? '';
    return !r.contains('MALIK') && !r.contains('OWNER');
  }

  bool get canWrite {
    final r = userRole?.toUpperCase() ?? '';
    return r.contains('YÖNETICI') || r.contains('MANAGER') || r.contains('ASSISTANT') || r.contains('ADMIN');
  }

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Rents
      try {
        final data = await _api.getRents();
        rents = data.map<RentModel>((j) => RentModel.fromJson(j)).toList();
      } catch (e) {
        error = 'Aidatlar yüklenemedi: $e';
        rents = [];
      }

      // Payments
      try {
        final data = await _api.getPayments();
        payments = data.map<PaymentModel>((j) => PaymentModel.fromJson(j)).toList();
      } catch (e) {
        error = error ?? 'Ödemeler yüklenemedi: $e';
        payments = [];
      }

      // Accounts
      try {
        final data = await _api.getCashBankAccounts();
        accounts = data.map<AccountModel>((j) => AccountModel.fromJson(j)).toList();
      } catch (e) {
        error = error ?? 'Hesaplar yüklenemedi: $e';
        accounts = [];
      }

      // Owners
      try {
        final data = await _api.getOwners();
        owners = data.map<Owner>((j) => Owner.fromJson(j)).toList();
      } catch (e) {
        error = error ?? 'Malikler yüklenemedi: $e';
        owners = [];
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  List<RentModel> get filteredRents {
    return rents.where((r) {
      final matchOwner = filterOwnerId == null || r.ownerId == filterOwnerId;
      final matchMonth = filterMonth == null || r.month == filterMonth;
      final matchYear = filterYear == null || r.year == filterYear;
      final matchStatus = filterStatus == null || r.status == filterStatus;
      return matchOwner && matchMonth && matchYear && matchStatus;
    }).toList();
  }

  double get filteredTotal => filteredRents.fold(0, (sum, r) => sum + r.amount);
  double get filteredPaidTotal {
    return filteredRents.where((r) => r.status == 'PAID').fold(0, (sum, r) => sum + r.amount);
  }
  double get filteredUnpaidTotal => filteredTotal - filteredPaidTotal;

  void setFilters({int? ownerId, int? month, int? year, String? status}) {
    filterOwnerId = ownerId;
    filterMonth = month;
    filterYear = year;
    filterStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    filterOwnerId = null;
    filterMonth = null;
    filterYear = DateTime.now().year;
    filterStatus = null;
    notifyListeners();
  }

  Future<bool> addRent({
    required int ownerId,
    required int month,
    required int year,
    required double amount,
    DateTime? dueDate,
    String? description,
  }) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }
    if (closedYears.contains(year)) {
      error = 'Kapalı mali yıl için işlem yapılamaz';
      notifyListeners();
      return false;
    }
    if (amount <= 0) {
      error = 'Tutar 0\'dan büyük olmalı';
      notifyListeners();
      return false;
    }

    try {
      await _api.createRent(
        userId: ownerId,
        month: month,
        year: year,
        amount: amount,
        dueDate: dueDate?.toIso8601String(),
        description: description,
      );
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> bulkAddRent({
    required int month,
    required int year,
    required double amount,
    DateTime? dueDate,
  }) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }
    if (closedYears.contains(year)) {
      error = 'Kapalı mali yıl için işlem yapılamaz';
      notifyListeners();
      return false;
    }
    if (amount <= 0) {
      error = 'Tutar 0\'dan büyük olmalı';
      notifyListeners();
      return false;
    }

    try {
      await _api.bulkCreateRent(
        month: month,
        year: year,
        amount: amount,
        dueDate: dueDate?.toIso8601String(),
      );
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRent(
    int rentId, {
    required double amount,
    DateTime? dueDate,
    String? description,
  }) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }

    final rent = rents.firstWhere((r) => r.id == rentId, orElse: () => RentModel(id: 0, ownerId: 0, month: 1, year: 2024, amount: 0, status: 'UNPAID'));
    if (rent.status == 'PAID') {
      error = 'Ödenmiş aidat düzenlenemez';
      notifyListeners();
      return false;
    }

    try {
      await _api.updateRent(
        rentId,
        amount: amount,
        dueDate: dueDate?.toIso8601String(),
        description: description,
      );
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRent(int rentId) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }

    final rent = rents.firstWhere((r) => r.id == rentId, orElse: () => RentModel(id: 0, ownerId: 0, month: 1, year: 2024, amount: 0, status: 'UNPAID'));
    if (rent.status == 'PAID') {
      error = 'Ödenmiş aidat silinemez';
      notifyListeners();
      return false;
    }

    try {
      await _api.deleteRent(rentId);
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> payRent({
    required int rentId,
    required int accountId,
    required double paidAmount,
    double? lateFeeAmount,
    DateTime? paymentDate,
    String? referenceNumber,
  }) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }

    try {
      await _api.createPayment(
        rentId: rentId,
        accountId: accountId,
        amount: paidAmount,
        lateFeeAmount: lateFeeAmount ?? 0,
        paymentDate: paymentDate?.toIso8601String(),
        referenceNumber: referenceNumber,
      );
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelPayment(int paymentId, {String? reason}) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }

    try {
      await _api.cancelPayment(paymentId, reason: reason);
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
