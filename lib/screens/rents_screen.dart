import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/rent_model.dart';
import '../models/payment_model.dart';
import '../providers/rent_provider.dart';
import '../providers/auth_provider.dart';
import 'add_edit_rent_page.dart';
import 'bulk_rent_page.dart';
import 'payment_page.dart';
import 'payment_cancel_dialog.dart';

class RentsScreen extends StatelessWidget {
  const RentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RentsView();
  }
}

class _RentsView extends StatefulWidget {
  const _RentsView();

  @override
  State<_RentsView> createState() => _RentsViewState();
}

class _RentsViewState extends State<_RentsView> {

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentProvider>();
    final rents = provider.filteredRents;
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    if (!provider.canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aidatlar')),
        body: const Center(child: Text('Erişim izniniz yok')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aidatlar'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'add') {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditRentPage()),
                );
                if (ok == true) provider.loadAll();
              } else if (value == 'bulk') {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const BulkRentPage()),
                );
                if (ok == true) provider.loadAll();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'add',
                enabled: provider.canWrite,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 20, color: provider.canWrite ? null : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Aidat Ekle', style: TextStyle(color: provider.canWrite ? null : Colors.grey)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bulk',
                enabled: provider.canWrite,
                child: Row(
                  children: [
                    Icon(Icons.post_add, size: 20, color: provider.canWrite ? null : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Toplu Aidat Ekle', style: TextStyle(color: provider.canWrite ? null : Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre Alanı
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: provider.filterOwnerId,
                        decoration: const InputDecoration(labelText: 'Malik', isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...provider.owners.map((o) => DropdownMenuItem(value: o.id, child: Text(o.fullName))),
                        ],
                        onChanged: (v) => provider.setFilters(ownerId: v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: provider.filterMonth,
                        decoration: const InputDecoration(labelText: 'Ay', isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM', 'tr_TR').format(DateTime(2024, i + 1))))),
                        ],
                        onChanged: (v) => provider.setFilters(month: v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: provider.filterYear,
                        decoration: const InputDecoration(labelText: 'Yıl', isDense: true),
                        items: List.generate(5, (i) {
                          final y = DateTime.now().year - i;
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }).toList(),
                        onChanged: (v) => provider.setFilters(year: v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: provider.filterStatus,
                        decoration: const InputDecoration(labelText: 'Durum', isDense: true),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Tümü')),
                          DropdownMenuItem(value: 'UNPAID', child: Text('Ödenmemiş')),
                          DropdownMenuItem(value: 'PAID', child: Text('Ödenmiş')),
                        ],
                        onChanged: (v) => provider.setFilters(status: v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Toplam Bilgi
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Toplam', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(currencyFormat.format(provider.filteredTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Ödenmiş', style: TextStyle(fontSize: 12, color: Colors.green)),
                    Text(currencyFormat.format(provider.filteredPaidTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Kalan', style: TextStyle(fontSize: 12, color: Colors.red)),
                    Text(currencyFormat.format(provider.filteredUnpaidTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                  ],
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : rents.isEmpty
                    ? const Center(child: Text('Aidat bulunamadı'))
                    : ListView.builder(
                        itemCount: rents.length,
                        itemBuilder: (_, i) {
                          final rent = rents[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(rent.ownerName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${DateFormat('MMMM yyyy', 'tr_TR').format(DateTime(rent.year, rent.month))}'),
                                  Text('Vade: ${rent.dueDate != null ? DateFormat('dd.MM.yyyy').format(rent.dueDate!) : 'Belirsiz'}'),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(currencyFormat.format(rent.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Chip(
                                    label: Text(rent.status == 'PAID' ? 'Ödenmiş' : 'Ödenmemiş', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: rent.status == 'PAID' ? Colors.green : Colors.orange,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              onTap: () => _showActions(context, provider, rent),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: provider.canWrite
          ? FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditRentPage()),
                );
                if (ok == true) provider.loadAll();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showActions(BuildContext context, RentProvider provider, RentModel rent) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Düzenle - sadece UNPAID ve canWrite
          if (provider.canWrite && rent.status == 'UNPAID')
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditRentPage(rent: rent)),
                ).then((_) => provider.loadAll());
              },
            ),
          // Sil - sadece UNPAID ve canWrite
          if (provider.canWrite && rent.status == 'UNPAID')
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, provider, rent);
              },
            ),
          // Ödeme Al - sadece UNPAID ve canWrite
          if (provider.canWrite && rent.status == 'UNPAID')
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('Ödeme Al'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentPage(rent: rent)),
                ).then((_) => provider.loadAll());
              },
            ),
          // Ödeme İptali - sadece PAID ve canWrite (Payments yoksa disabled)
          if (provider.canWrite && rent.status == 'PAID')
            ListTile(
              leading: const Icon(Icons.undo, color: Colors.orange),
              title: const Text('Ödeme İptali'),
              onTap: () {
                Navigator.pop(context);
                // Aidattan bağlı olan payment'ları bul
                final payments = provider.payments.where((p) => p.rentId == rent.id && !(p.isCancelled ?? false)).toList();
                if (payments.isNotEmpty) {
                  final payment = payments.first;
                  showDialog(
                    context: context,
                    builder: (_) => PaymentCancelDialog(
                      paymentId: payment.id,
                      totalAmount: payment.amount,
                    ),
                  ).then((_) => provider.loadAll());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu aidata ait ödeme bulunamadı')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, RentProvider provider, RentModel rent) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aidat Sil'),
        content: const Text('Silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await provider.deleteRent(rent.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Aidat silindi' : provider.error ?? 'Hata')),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
