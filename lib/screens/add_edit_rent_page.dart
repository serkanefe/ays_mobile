import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/rent_model.dart';
import '../providers/rent_provider.dart';

class AddEditRentPage extends StatefulWidget {
  final RentModel? rent;

  const AddEditRentPage({super.key, this.rent});

  @override
  State<AddEditRentPage> createState() => _AddEditRentPageState();
}

class _AddEditRentPageState extends State<AddEditRentPage> {
  late TextEditingController amountCtrl, descCtrl, dueDateCtrl;
  int? selectedOwnerId, selectedMonth, selectedYear;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    amountCtrl = TextEditingController(text: widget.rent?.amount.toStringAsFixed(2) ?? '');
    descCtrl = TextEditingController(text: widget.rent?.description ?? '');
    dueDateCtrl = TextEditingController(
      text: widget.rent?.dueDate != null ? DateFormat('dd.MM.yyyy').format(widget.rent!.dueDate!) : '',
    );
    selectedOwnerId = widget.rent?.ownerId;
    selectedMonth = widget.rent?.month ?? DateTime.now().month;
    selectedYear = widget.rent?.year ?? DateTime.now().year;
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    descCtrl.dispose();
    dueDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentProvider>();
    final isEdit = widget.rent != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Aidat Düzenle' : 'Yeni Aidat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int?>(
              value: selectedOwnerId,
              decoration: const InputDecoration(labelText: 'Malik *'),
              items: provider.owners.map((o) => DropdownMenuItem(value: o.id, child: Text(o.fullName))).toList(),
              onChanged: (v) => setState(() => selectedOwnerId = v),
              validator: (v) => v == null ? 'Seçiniz' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedMonth,
                    decoration: const InputDecoration(labelText: 'Ay *'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Seçiniz')),
                      ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM', 'tr_TR').format(DateTime(2024, i + 1))))).toList()
                    ],
                    onChanged: (v) => setState(() => selectedMonth = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: 'Yıl *'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Seçiniz')),
                      ...List.generate(5, (i) {
                        final y = DateTime.now().year - i;
                        return DropdownMenuItem(value: y, child: Text('$y'));
                      }).toList()
                    ],
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
                final date = await showDatePicker(context: context, initialDate: widget.rent?.dueDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (date != null) dueDateCtrl.text = DateFormat('dd.MM.yyyy').format(date);
              },
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : () => _save(provider),
                child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(RentProvider provider) async {
    if (selectedOwnerId == null || selectedMonth == null || selectedYear == null || amountCtrl.text.isEmpty) {
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

    final ok = widget.rent == null 
      ? await provider.addRent(ownerId: selectedOwnerId!, month: selectedMonth!, year: selectedYear!, amount: double.tryParse(amountCtrl.text) ?? 0, dueDate: dueDate, description: descCtrl.text)
      : await provider.updateRent(widget.rent!.id, amount: double.tryParse(amountCtrl.text) ?? 0, dueDate: dueDate, description: descCtrl.text);

    setState(() => isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? (widget.rent == null ? 'Aidat eklendi' : 'Aidat güncellendi') : provider.error ?? 'Hata')));
      if (ok) Navigator.pop(context, true);
    }
  }
}
