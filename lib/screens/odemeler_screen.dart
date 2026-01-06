import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class OdemelerScreen extends StatelessWidget {
  const OdemelerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödemeler'),
      ),
      body: const EmptyState(
        message: 'Ödemeler Raporu',
        icon: Icons.payment,
      ),
    );
  }
}
