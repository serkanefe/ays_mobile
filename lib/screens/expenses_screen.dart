import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../models/expense_model.dart';
import 'add_edit_expense_page.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().user?.role;
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider(userRole: role)..loadAll(),
      child: const _ExpensesView(),
    );
  }
}

class _ExpensesView extends StatefulWidget {
  const _ExpensesView();

  @override
  State<_ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<_ExpensesView> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExpenseProvider>();
    _searchCtrl.addListener(() => provider.setSearch(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final canView = provider.canView;
    final canWrite = provider.canWrite;

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giderler')),
        body: const Center(child: Text('Bu alana erişim yetkiniz yok')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giderler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _openFilters(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.loadAll,
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Gider Ekle'),
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const AddEditExpensePage(),
                    ),
                  ),
                );
                if (changed == true && mounted) provider.loadAll();
              },
            )
          : null,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, provider, canWrite),
    );
  }

  Widget _buildContent(BuildContext context, ExpenseProvider provider, bool canWrite) {
    final expenses = provider.filteredExpenses;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Gider adı ara',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          _TotalCard(total: provider.filteredTotal, count: expenses.length),
          const SizedBox(height: 12),
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text('Gider bulunamadı'))
                : ListView.separated(
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final e = expenses[i];
                      return _ExpenseTile(
                        expense: e,
                        currency: currency,
                        onEdit: canWrite
                            ? () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider.value(
                                      value: provider,
                                      child: AddEditExpensePage(expense: e),
                                    ),
                                  ),
                                );
                                if (changed == true && mounted) provider.loadAll();
                              }
                            : null,
                        onDelete: canWrite
                            ? () async {
                                final ok = await _confirmDelete(context);
                                if (ok == true) {
                                  final success = await provider.deleteExpense(e);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Gider silindi')),
                                    );
                                  }
                                }
                              }
                            : null,
                        onTap: () => _showDetails(context, e, currency),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, ExpenseProvider provider) async {
    final categories = provider.categories;
    final accounts = provider.accounts;
    final payeeCtrl = TextEditingController(text: provider.filterPayee ?? '');
    DateTimeRange? tempRange = provider.filterDateRange;
    int? tempCat = provider.filterCategoryId;
    int? tempAcc = provider.filterAccountId;

    await showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Filtreler', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<int>(
                    value: tempCat,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c.id ?? 0, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => tempCat = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: tempAcc,
                    decoration: const InputDecoration(labelText: 'Hesap'),
                    items: accounts
                        .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (v) => setState(() => tempAcc = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: payeeCtrl,
                    decoration: const InputDecoration(labelText: 'Ödenen firma/kişi'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(tempRange == null
                          ? 'Tarih aralığı: seçilmedi'
                          : '${DateFormat('dd.MM.yyyy').format(tempRange!.start)} - ${DateFormat('dd.MM.yyyy').format(tempRange!.end)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(now.year - 5),
                            lastDate: DateTime(now.year + 5),
                            initialDateRange: tempRange,
                          );
                          if (picked != null) {
                            setState(() => tempRange = picked);
                          }
                        },
                        child: const Text('Tarih Seç'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.setFilters(
                        categoryId: tempCat,
                        accountId: tempAcc,
                        payee: payeeCtrl.text.trim().isEmpty ? null : payeeCtrl.text.trim(),
                        range: tempRange,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Uygula'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gideri sil'),
        content: const Text('Bu gider silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, ExpenseModel e, NumberFormat currency) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                  Text(currency.format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('Kategori', e.categoryName ?? '-'),
              _detailRow('Tarih', _fmtDate(e.date)),
              _detailRow('Hesap', e.accountName ?? ''),
              _detailRow('Ödenen', e.payee ?? ''),
              _detailRow('Makbuz', e.receiptNo ?? ''),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.count});
  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments),
          const SizedBox(width: 10),
          Expanded(child: Text('Toplam Gider ($count kayıt)', style: const TextStyle(fontWeight: FontWeight.w600))),
          Text('₺${total.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.currency,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final ExpenseModel expense;
  final NumberFormat currency;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.categoryName ?? ''),
            const SizedBox(height: 4),
            Text('${_fmtDate(expense.date)} • ${expense.payee ?? ''}'),
            Text('Hesap: ${expense.accountName ?? ''}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currency.format(expense.amount), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            if (onEdit != null || onDelete != null)
              Wrap(
                spacing: 4,
                children: [
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  return DateFormat('dd.MM.yyyy').format(d);
}
