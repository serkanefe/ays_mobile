import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../providers/expense_provider.dart';

class AddEditExpensePage extends StatefulWidget {
  const AddEditExpensePage({super.key, this.expense});

  final ExpenseModel? expense;

  @override
  State<AddEditExpensePage> createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends State<AddEditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _payeeCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _categoryId;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _nameCtrl.text = e.name;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _payeeCtrl.text = e.payee ?? '';
      _receiptCtrl.text = e.receiptNo ?? '';
      _selectedDate = e.date ?? DateTime.now();
      _categoryId = e.categoryId;
      _accountId = e.accountId;
    } else {
      _receiptCtrl.text = _generateReceiptNo();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _payeeCtrl.dispose();
    _receiptCtrl.dispose();
    super.dispose();
  }

  String _generateReceiptNo() {
    final now = DateTime.now();
    return 'RCPT-${DateFormat('yyyyMMdd-HHmmss').format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final categories = provider.categories;
    final accounts = provider.accounts;
    final isEdit = widget.expense != null;
    final dateLabel = DateFormat('dd.MM.yyyy').format(_selectedDate);

    if (provider.isLoading && categories.isEmpty && accounts.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Gideri Düzenle' : 'Gider Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Gider Adı *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Gider adı gerekli' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori *'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id ?? 0, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Kategori seçin' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tarih *'),
                  child: Text(dateLabel),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Tutar *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null || value <= 0) return 'Tutar 0’dan büyük olmalı';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _payeeCtrl,
                decoration: const InputDecoration(labelText: 'Ödenen Firma/Kişi *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _accountId,
                decoration: const InputDecoration(labelText: 'Hesap (Kasa/Banka) *'),
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} (${a.type == 'CASH' ? 'Kasa' : 'Banka'})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _accountId = v),
                validator: (v) => v == null ? 'Hesap seçin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receiptCtrl,
                decoration: const InputDecoration(labelText: 'Makbuz No'),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: provider.isLoading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  final ok = await _submit(provider);
                  if (ok && mounted) {
                    Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'Güncelle' : 'Kaydet'),
              ),
              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Text(provider.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _submit(ExpenseProvider provider) async {
    final name = _nameCtrl.text.trim();
    final payee = _payeeCtrl.text.trim();
    final receipt = _receiptCtrl.text.trim().isEmpty ? _generateReceiptNo() : _receiptCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (_categoryId == null || _accountId == null) return false;

    if (widget.expense == null) {
      return provider.addExpense(
        name: name,
        categoryId: _categoryId!,
        date: _selectedDate,
        amount: amount,
        accountId: _accountId!,
        payee: payee,
        receiptNo: receipt,
      );
    }

    return provider.updateExpense(
      widget.expense!,
      name: name,
      categoryId: _categoryId!,
      date: _selectedDate,
      amount: amount,
      accountId: _accountId!,
      payee: payee,
      receiptNo: receipt,
    );
  }
}
