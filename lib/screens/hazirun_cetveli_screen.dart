import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class HazirunCetveliScreen extends StatelessWidget {
  const HazirunCetveliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hazirun Cetveli'),
      ),
      body: const EmptyState(
        message: 'Hazirun Cetveli',
        icon: Icons.checklist,
      ),
    );
  }
}
