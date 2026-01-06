import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class BorcDurumuScreen extends StatelessWidget {
  const BorcDurumuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borç Durumu'),
      ),
      body: const EmptyState(
        message: 'Borç Durumu Raporu',
        icon: Icons.warning,
      ),
    );
  }
}
