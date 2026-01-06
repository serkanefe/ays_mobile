import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/rent_model.dart';
import '../providers/rent_provider.dart';
import 'payment_cancel_dialog.dart';

class PaymentPage extends StatefulWidget {
  final RentModel rent;

  const PaymentPage({super.key, required this.rent});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late TextEditingController amountCtrl, lateFeeCtrl, dateCtrl, refCtrl;
  int? selectedAccountId;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    amountCtrl = TextEditingController(text: widget.rent.amount.toStringAsFixed(2));
    lateFeeCtrl = TextEditingController(text: '0');
    dateCtrl = TextEditingController(text: DateFormat('dd.MM.yyyy').format(DateTime.now()));
    refCtrl = TextEditingController();
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    lateFeeCtrl.dispose();
    dateCtrl.dispose();
    refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Al')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aidat Bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Malik: ${widget.rent.ownerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('${DateFormat('MMMM yyyy', 'tr_TR').format(DateTime(widget.rent.year, widget.rent.month))}'),
                    const SizedBox(height: 8),
                    Text('Vade: ${widget.rent.dueDate != null ? DateFormat('dd.MM.yyyy').format(widget.rent.dueDate!) : 'Belirsiz'}'),
                    const SizedBox(height: 8),
                    Text('Tutar: ${currencyFormat.format(widget.rent.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ödeme Detayları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Ödenen Tutar *', suffixText: '₺'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: lateFeeCtrl,
              decoration: const InputDecoration(labelText: 'Gecikme Cezası', suffixText: '₺'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateCtrl,
              decoration: const InputDecoration(labelText: 'Ödeme Tarihi (dd.MM.yyyy)', suffixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (date != null) dateCtrl.text = DateFormat('dd.MM.yyyy').format(date);
              },
              readOnly: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: selectedAccountId,
              decoration: const InputDecoration(labelText: 'Kasa/Banka *'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Seçiniz')),
                ...provider.accounts
                    .map((acc) => DropdownMenuItem<int?>(
                          value: acc.id,
                          child: Text(acc.name),
                        ))
                    .toList()
              ],
              onChanged: (val) => setState(() => selectedAccountId = val),
              validator: (val) => val == null ? 'Kasa/Banka seçiniz' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: refCtrl,
              decoration: const InputDecoration(labelText: 'Makbuz No / Referans'),
            ),
            const SizedBox(height: 20),
            // Toplam
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam Ödeme:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormat.format((double.tryParse(amountCtrl.text) ?? 0) + (double.tryParse(lateFeeCtrl.text) ?? 0)),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : () => _save(provider),
                child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Ödemeyi Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(RentProvider provider) async {
    final amount = double.tryParse(amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar giriniz')));
      return;
    }

    if (selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kasa/Banka seçiniz')));
      return;
    }

    setState(() => isSaving = true);

    DateTime? paymentDate;
    try {
      paymentDate = DateFormat('dd.MM.yyyy').parse(dateCtrl.text);
    } catch (_) {
      paymentDate = DateTime.now();
    }

    final ok = await provider.payRent(
      rentId: widget.rent.id,
      accountId: selectedAccountId!,
      paidAmount: amount,
      lateFeeAmount: double.tryParse(lateFeeCtrl.text),
      paymentDate: paymentDate,
      referenceNumber: refCtrl.text,
    );

    setState(() => isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Ödeme alındı' : provider.error ?? 'Hata')));
      if (ok) Navigator.pop(context, true);
    }
  }
}
