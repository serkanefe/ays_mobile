import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class AddOwnerScreen extends StatelessWidget {
  const AddOwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malik Ekle'),
      ),
      body: const EmptyState(
        message: 'Malik ekleme formu hazır',
        icon: Icons.person_add,
      ),
    );
  }
}
