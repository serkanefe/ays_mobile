import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class TahsilatlarScreen extends StatelessWidget {
  const TahsilatlarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahsilatlar'),
      ),
      body: const EmptyState(
        message: 'Tahsilatlar Raporu',
        icon: Icons.receipt,
      ),
    );
  }
}
