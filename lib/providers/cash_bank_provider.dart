import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class CashBankProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<AccountModel> accounts = [];
  List<TransactionModel> transactions = [];
  bool isLoading = false;
  String? error;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([fetchAccounts(), fetchTransactions()]);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAccounts() async {
    final data = await _api.getCashBankAccounts();
    accounts = data.map<AccountModel>((j) => AccountModel.fromJson(j)).toList();
  }

  Future<void> fetchTransactions() async {
    final data = await _api.getCashBankTransactions();
    transactions = data.map<TransactionModel>((j) => TransactionModel.fromJson(j)).toList();
  }

  double get cashBalance => accounts
      .where((a) => a.type == 'CASH')
      .fold(0.0, (sum, a) => sum + a.balance);

  double get bankBalance => accounts
      .where((a) => a.type == 'BANK')
      .fold(0.0, (sum, a) => sum + a.balance);

  Future<bool> addAccount({required String name, required String type, double openingBalance = 0}) async {
    try {
      await _api.createCashBankAccount(name: name, type: type, openingBalance: openingBalance);
      await fetchAccounts();
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addIncome({required int accountId, required double amount, String? description}) async {
    try {
      await _api.createCashBankIncome(accountId: accountId, amount: amount, description: description);
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addExpense({required int accountId, required double amount, String? description}) async {
    try {
      await _api.createCashBankExpense(accountId: accountId, amount: amount, description: description);
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTransfer({
    required int sourceAccountId,
    required int targetAccountId,
    required double amount,
    String? description,
  }) async {
    try {
      await _api.createCashBankTransfer(
        sourceAccountId: sourceAccountId,
        targetAccountId: targetAccountId,
        amount: amount,
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

  Future<bool> cancelTx(int txId) async {
    try {
      await _api.cancelTransaction(txId);
      await loadAll();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
