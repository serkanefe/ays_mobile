import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class UnpaidRentsScreen extends StatelessWidget {
  const UnpaidRentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödenmemiş Aidatlar'),
      ),
      body: const EmptyState(
        message: 'Ödenmemiş aidatlar ekranı hazır',
        icon: Icons.warning,
      ),
    );
  }
}
