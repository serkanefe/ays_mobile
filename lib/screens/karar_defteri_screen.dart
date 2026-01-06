import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class KararDefteriScreen extends StatelessWidget {
  const KararDefteriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karar Defteri'),
      ),
      body: const EmptyState(
        message: 'Karar Defteri',
        icon: Icons.description,
      ),
    );
  }
}
