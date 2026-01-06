import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class DaireListesiScreen extends StatelessWidget {
  const DaireListesiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daire Listesi'),
      ),
      body: const EmptyState(
        message: 'Daire Listesi Raporu',
        icon: Icons.list,
      ),
    );
  }
}
