import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  ExpenseProvider({required this.userRole, this.allowNegativeBalance = false, Set<int>? closedYears})
      : closedYears = closedYears ?? {};

  final String? userRole; // MANAGER / ASSISTANT_MANAGER / INSPECTOR / OWNER
  final bool allowNegativeBalance;
  final Set<int> closedYears;

  final ApiService _api = ApiService();

  List<ExpenseModel> expenses = [];
  List<AccountModel> accounts = [];
  List<Category> categories = [];
  // Bakım anlaşması entegrasyonu kaldırıldı

  bool isLoading = false;
  String? error;

  // Filters
  String searchText = '';
  int? filterCategoryId;
  int? filterAccountId;
  String? filterPayee;
  DateTimeRange? filterDateRange;

  bool get canView {
    final r = userRole?.toUpperCase();
    return r != 'OWNER';
  }

  bool get canWrite {
    final r = userRole?.toUpperCase();
    if (r == 'OWNER') return false;
    if (r == 'INSPECTOR') return false;
    return true; // MANAGER, ASSISTANT_MANAGER ve diğer roller için yazma açık
  }

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Expenses
      try {
        final data = await _api.getExpenses();
        expenses = data.map<ExpenseModel>((j) => ExpenseModel.fromJson(j)).toList();
      } catch (e) {
        error = 'Giderler yüklenemedi: $e';
        expenses = [];
      }

      // Accounts
      try {
        final data = await _api.getCashBankAccounts();
        accounts = data.map<AccountModel>((j) => AccountModel.fromJson(j)).toList();
      } catch (e) {
        error = error ?? 'Hesaplar yüklenemedi: $e';
        accounts = [];
      }

      // Categories
      try {
        final data = await _api.getCategories();
        categories = data
            .map<Category>((j) => Category.fromJson(j as Map<String, dynamic>))
            .where((c) => c.categoryType == 'EXPENSE')
            .toList();
      } catch (e) {
        error = error ?? 'Kategoriler yüklenemedi: $e';
        categories = [];
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  List<ExpenseModel> get filteredExpenses {
    return expenses.where((e) {
      final matchText = searchText.isEmpty || e.name.toLowerCase().contains(searchText.toLowerCase());
      final matchCategory = filterCategoryId == null || e.categoryId == filterCategoryId;
      final matchAccount = filterAccountId == null || e.accountId == filterAccountId;
      final matchPayee = (filterPayee == null || filterPayee!.isEmpty)
          ? true
          : (e.payee ?? '').toLowerCase().contains(filterPayee!.toLowerCase());
      final matchDate = filterDateRange == null
          ? true
          : (e.date != null &&
              !e.date!.isBefore(filterDateRange!.start) &&
              !e.date!.isAfter(filterDateRange!.end));
      return matchText && matchCategory && matchAccount && matchPayee && matchDate;
    }).toList();
  }

  double get filteredTotal => filteredExpenses.fold(0, (sum, e) => sum + e.amount);

  void setSearch(String value) {
    searchText = value;
    notifyListeners();
  }

  void setFilters({int? categoryId, int? accountId, String? payee, DateTimeRange? range}) {
    filterCategoryId = categoryId;
    filterAccountId = accountId;
    filterPayee = payee;
    filterDateRange = range;
    notifyListeners();
  }

  void clearFilters() {
    filterCategoryId = null;
    filterAccountId = null;
    filterPayee = null;
    filterDateRange = null;
    notifyListeners();
  }

  Future<bool> addExpense({
    required String name,
    required int categoryId,
    required DateTime date,
    required double amount,
    required int accountId,
    String? payee,
    String? receiptNo,
  }) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }
    if (closedYears.contains(date.year)) {
      error = 'Kapalı mali yıl için işlem yapılamaz';
      notifyListeners();
      return false;
    }
    if (amount <= 0) {
      error = 'Tutar 0’dan büyük olmalı';
      notifyListeners();
      return false;
    }

    final acc = accounts.firstWhere((a) => a.id == accountId, orElse: () => AccountModel(id: 0, name: '', type: 'CASH', balance: 0, isActive: true));
    if (!allowNegativeBalance && acc.id != 0 && acc.balance < amount) {
      error = 'Hesap bakiyesi yetersiz';
      notifyListeners();
      return false;
    }

    try {
      await _api.createExpense(
        name: name,
        categoryId: categoryId,
        amount: amount,
        accountId: accountId,
        payee: payee,
        receiptNo: receiptNo,
        date: date.toIso8601String(),
      );
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(
    ExpenseModel existing, {
    required String name,
    required int categoryId,
    required DateTime date,
    required double amount,
    required int accountId,
    String? payee,
    String? receiptNo,
  }) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }
    if (closedYears.contains(date.year)) {
      error = 'Kapalı mali yıl için işlem yapılamaz';
      notifyListeners();
      return false;
    }
    if (amount <= 0) {
      error = 'Tutar 0’dan büyük olmalı';
      notifyListeners();
      return false;
    }

    final acc = accounts.firstWhere((a) => a.id == accountId, orElse: () => AccountModel(id: 0, name: '', type: 'CASH', balance: 0, isActive: true));
    final restoredBalance = acc.id == 0 ? 0 : acc.balance + existing.amount;
    if (!allowNegativeBalance && acc.id != 0 && restoredBalance < amount) {
      error = 'Hesap bakiyesi yetersiz';
      notifyListeners();
      return false;
    }

    try {
      await _api.updateExpense(
        existing.id,
        categoryId: categoryId,
        amount: amount,
        date: date.toIso8601String(),
        payee: payee,
        name: name,
        receiptNo: receiptNo,
        accountId: accountId,
      );
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(ExpenseModel expense) async {
    if (!canWrite) {
      error = 'Bu işlem için yetkiniz yok';
      notifyListeners();
      return false;
    }
    if (expense.date != null && closedYears.contains(expense.date!.year)) {
      error = 'Kapalı mali yıl için işlem yapılamaz';
      notifyListeners();
      return false;
    }
    try {
      await _api.deleteExpense(expense.id);
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
