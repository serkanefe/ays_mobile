import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödemeler'),
      ),
      body: const EmptyState(
        message: 'Ödemeler ekranı hazır',
        icon: Icons.money,
      ),
    );
  }
}
