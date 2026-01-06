import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/rent_provider.dart';

class BulkRentPage extends StatefulWidget {
  const BulkRentPage({super.key});

  @override
  State<BulkRentPage> createState() => _BulkRentPageState();
}

class _BulkRentPageState extends State<BulkRentPage> {
  late TextEditingController amountCtrl, dueDateCtrl;
  int? selectedMonth, selectedYear;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    amountCtrl = TextEditingController();
    dueDateCtrl = TextEditingController();
    selectedMonth = DateTime.now().month;
    selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    dueDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Toplu Aidat Oluştur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text('Bu ay ve yıl için seçili tüm malikler için aidat oluşturulacak.'),
                    const SizedBox(height: 8),
                    Text('Aktif malik sayısı: ${provider.owners.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedMonth,
                    decoration: const InputDecoration(labelText: 'Ay *'),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM', 'tr_TR').format(DateTime(2024, i + 1))))).toList(),
                    onChanged: (v) => setState(() => selectedMonth = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: 'Yıl *'),
                    items: List.generate(5, (i) {
                      final y = DateTime.now().year - i;
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedYear = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Tutar *', suffixText: '₺'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dueDateCtrl,
              decoration: const InputDecoration(labelText: 'Vade Tarihi (dd.MM.yyyy)', suffixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (date != null) dueDateCtrl.text = DateFormat('dd.MM.yyyy').format(date);
              },
              readOnly: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : () => _save(provider),
                child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(RentProvider provider) async {
    if (selectedMonth == null || selectedYear == null || amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zorunlu alanları doldurunuz')));
      return;
    }

    setState(() => isSaving = true);

    DateTime? dueDate;
    if (dueDateCtrl.text.isNotEmpty) {
      try {
        dueDate = DateFormat('dd.MM.yyyy').parse(dueDateCtrl.text);
      } catch (_) {}
    }

    final result = await provider.bulkAddRent(
      month: selectedMonth!,
      year: selectedYear!,
      amount: double.tryParse(amountCtrl.text) ?? 0,
      dueDate: dueDate,
    );

    setState(() => isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ? 'Aidatlar oluşturuldu' : provider.error ?? 'Hata')),
      );
      if (result) Navigator.pop(context, true);
    }
  }
}
