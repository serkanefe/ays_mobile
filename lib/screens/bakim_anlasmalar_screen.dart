import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class BakimAnlasmalarScreen extends StatelessWidget {
  const BakimAnlasmalarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakım Anlaşmaları'),
      ),
      body: const EmptyState(
        message: 'Bakım Anlaşmaları',
        icon: Icons.handshake,
      ),
    );
  }
}
