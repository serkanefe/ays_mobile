import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
      ),
      body: const EmptyState(
        message: 'Raporlar ekranı hazır',
        icon: Icons.bar_chart,
      ),
    );
  }
}
