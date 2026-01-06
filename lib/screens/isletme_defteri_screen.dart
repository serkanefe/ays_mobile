import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class IsletmeDefteriScreen extends StatelessWidget {
  const IsletmeDefteriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşletme Defteri'),
      ),
      body: const EmptyState(
        message: 'İşletme Defteri',
        icon: Icons.description,
      ),
    );
  }
}
