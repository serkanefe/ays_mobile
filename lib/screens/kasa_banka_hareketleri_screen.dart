import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account_model.dart';
import '../providers/cash_bank_provider.dart';

class KasaBankaHareketleriScreen extends StatefulWidget {
  const KasaBankaHareketleriScreen({super.key});

  @override
  State<KasaBankaHareketleriScreen> createState() => _KasaBankaHareketleriScreenState();
}

class _KasaBankaHareketleriScreenState extends State<KasaBankaHareketleriScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CashBankProvider()..loadAll(),
      child: Consumer<CashBankProvider>(
        builder: (context, provider, _) {
          final kasaBalance = provider.cashBalance;
          final bankaBalance = provider.bankBalance;
          final totalBalance = kasaBalance + bankaBalance;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Kasa / Banka'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.loadAll(),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Hareket Ekle'),
              onPressed: () => _openActionSheet(context, provider),
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BalanceRow(
                          kasa: kasaBalance,
                          banka: bankaBalance,
                          toplam: totalBalance,
                        ),
                        const SizedBox(height: 16),
                        _AccountsTable(accounts: provider.accounts),
                        const SizedBox(height: 12),
                        const Expanded(child: _PlaceholderArea()),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _openActionSheet(BuildContext context, CashBankProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.add_card),
                title: const Text('Hesap Oluştur'),
                onTap: () {
                  Navigator.pop(context);
                  _showAccountDialog(context, provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Transfer'),
                onTap: () {
                  Navigator.pop(context);
                  _showTransferDialog(context, provider);
                },
              ),
            ],
          ),
        );
      },
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
              value: type,
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

  Future<void> _showTransferDialog(BuildContext context, CashBankProvider provider) async {
    if (provider.accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En az iki hesap gerekli.')));
      return;
    }

    AccountModel src = provider.accounts.first;
    AccountModel? dst;

    List<AccountModel> _targets(AccountModel s) {
      return provider.accounts.where((a) => a.id != s.id && a.type != s.type).toList();
    }

    List<AccountModel> targetList = _targets(src);
    if (targetList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karşı tipte başka hesap yok. Önce kasa veya banka hesabı ekleyin.')),
      );
      return;
    }
    dst = targetList.first;

    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final availableTargets = _targets(src);
          if (availableTargets.isNotEmpty && (dst == null || !availableTargets.contains(dst))) {
            dst = availableTargets.first;
          }

          return AlertDialog(
            title: const Text('Transfer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AccountModel>(
                  value: src,
                  items: provider.accounts
                      .map((a) => DropdownMenuItem(value: a, child: Text('Kaynak: ${a.name} (${a.type})')))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      src = v ?? src;
                      final candidates = _targets(src);
                      dst = candidates.isNotEmpty ? candidates.first : null;
                    });
                  },
                ),
                DropdownButtonFormField<AccountModel>(
                  value: dst,
                  items: availableTargets
                      .map((a) => DropdownMenuItem(value: a, child: Text('Hedef: ${a.name} (${a.type})')))
                      .toList(),
                  onChanged: (v) => setState(() => dst = v ?? dst),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tutar'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Gönder')),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      if (amount <= 0 || dst == null || src.id == dst!.id) return;
      await provider.addTransfer(
        sourceAccountId: src.id,
        targetAccountId: dst!.id,
        amount: amount,
        description: descCtrl.text.trim(),
      );
    }
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.kasa, required this.banka, required this.toplam});
  final double kasa;
  final double banka;
  final double toplam;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Kasa', value: kasa)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Banka', value: banka)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Toplam', value: toplam, emphasize: true)),
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

class _AccountsTable extends StatelessWidget {
  const _AccountsTable({required this.accounts});
  final List<AccountModel> accounts;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Text('Hesap bulunamadı.');
    }

    final color = Theme.of(context).colorScheme.primary;
    final total = accounts.fold<double>(0, (sum, a) => sum + a.balance);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_wallet, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hesaplar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${accounts.length} aktif hesap', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Toplam ${total.toStringAsFixed(2)} TL', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...accounts.map((a) {
              final badgeColor = a.type == 'CASH' ? Colors.orange : Colors.blue;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                a.type == 'CASH' ? 'Kasa' : 'Banka',
                                style: TextStyle(color: badgeColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${a.balance.toStringAsFixed(2)} TL',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (a != accounts.last) const Divider(height: 1),
                  if (a != accounts.last) const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
 
class _PlaceholderArea extends StatelessWidget {
  const _PlaceholderArea();
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
