import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class FaaliyetRaporuScreen extends StatelessWidget {
  const FaaliyetRaporuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faaliyet Raporu'),
      ),
      body: const EmptyState(
        message: 'Faaliyet Raporu',
        icon: Icons.assessment,
      ),
    );
  }
}
