import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class BilancoScreen extends StatelessWidget {
  const BilancoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilanço'),
      ),
      body: const EmptyState(
        message: 'Bilanço Raporu',
        icon: Icons.balance,
      ),
    );
  }
}
