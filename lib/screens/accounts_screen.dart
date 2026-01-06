import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cash_bank_provider.dart';
import '../models/account_model.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CashBankProvider()..loadAll(),
      child: Consumer<CashBankProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Kasa / Banka Hesapları'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.loadAll,
                )
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Hesap Oluştur'),
              onPressed: () => _showAccountDialog(context, provider),
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryRow(
                          cash: provider.cashBalance,
                          bank: provider.bankBalance,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: provider.accounts.isEmpty
                              ? const _EmptyState()
                              : ListView.separated(
                                  itemCount: provider.accounts.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, i) => _AccountTile(provider.accounts[i]),
                                ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _showAccountDialog(BuildContext context, CashBankProvider provider) async {
    final nameCtrl = TextEditingController();
    String type = 'CASH';
    final balanceCtrl = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hesap Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Hesap adı')),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('Kasa')),
                DropdownMenuItem(value: 'BANK', child: Text('Banka')),
              ],
              onChanged: (v) => type = v ?? 'CASH',
              decoration: const InputDecoration(labelText: 'Tip'),
            ),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Açılış bakiyesi'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oluştur')),
        ],
      ),
    );
    if (ok == true) {
      final amount = double.tryParse(balanceCtrl.text) ?? 0;
      await provider.addAccount(name: nameCtrl.text.trim(), type: type, openingBalance: amount);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.cash, required this.bank});
  final double cash;
  final double bank;

  @override
  Widget build(BuildContext context) {
    final total = cash + bank;
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Kasa', value: cash)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Banka', value: bank)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Toplam', value: total, emphasize: true)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, this.emphasize = false});
  final String title;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final color = emphasize ? Theme.of(context).colorScheme.primary : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('${value.toStringAsFixed(2)} TL',
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile(this.account);
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final color = account.type == 'CASH' ? Colors.orange : Colors.blue;
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).cardColor,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(account.type == 'CASH' ? Icons.account_balance_wallet : Icons.account_balance, color: color),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${account.type} • ${account.isActive ? 'Aktif' : 'Pasif'}'),
        trailing: Text(
          '${account.balance.toStringAsFixed(2)} TL',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Hesap yok, ekle düğmesini kullanın.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
