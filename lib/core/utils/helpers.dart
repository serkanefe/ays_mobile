import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Helpers {
  // Tarih formatlama
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  // Para formatlama
  static String formatCurrency(double? amount) {
    if (amount == null) return '0,00 ₺';
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Ay adı getir
  static String getMonthName(int month) {
    if (month < 1 || month > 12) return '-';
    return AppConstants.months[month - 1];
  }

  // Durum rengi
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'UNPAID':
        return Colors.red;
      case 'PARTIAL':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Durum metni
  static String getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Ödendi';
      case 'UNPAID':
        return 'Ödenmedi';
      case 'PARTIAL':
        return 'Kısmi';
      default:
        return status;
    }
  }

  // Snackbar göster
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Onay dialogu
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Evet',
    String cancelText = 'Hayır',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Email validasyonu
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  // Şifre validasyonu
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Şifre en az ${AppConstants.minPasswordLength} karakter olmalı';
    }
    return null;
  }

  // Boş alan validasyonu
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gerekli';
    }
    return null;
  }

  // Sayı validasyonu
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName gerekli';
    }
    if (double.tryParse(value) == null) {
      return 'Geçerli bir sayı girin';
    }
    return null;
  }
}
