import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rent_provider.dart';

class PaymentCancelDialog extends StatefulWidget {
  final int paymentId;
  final double totalAmount;

  const PaymentCancelDialog({
    super.key,
    required this.paymentId,
    required this.totalAmount,
  });

  @override
  State<PaymentCancelDialog> createState() => _PaymentCancelDialogState();
}

class _PaymentCancelDialogState extends State<PaymentCancelDialog> {
  late TextEditingController reasonCtrl;
  bool isCancelling = false;

  @override
  void initState() {
    super.initState();
    reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ödemeyi İptal Et'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dikkat: Bu işlem tersine çevrilemez.',
              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'İptal Edilecek Tutar: ₺${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'İptal Nedeni',
                hintText: 'Ödemeyi neden iptal ediyorsunuz?',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isCancelling ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: isCancelling ? null : () => _cancel(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: isCancelling
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('İptal Et', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _cancel(BuildContext context) async {
    if (reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İptal nedenini giriniz')));
      return;
    }

    setState(() => isCancelling = true);

    final provider = context.read<RentProvider>();
    final ok = await provider.cancelPayment(widget.paymentId, reason: reasonCtrl.text);

    setState(() => isCancelling = false);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ödeme iptal edildi')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Hata')),
      );
    }
  }
}
