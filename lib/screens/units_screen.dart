import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit_model.dart';
import '../providers/unit_provider.dart';
import '../core/utils/helpers.dart';
import 'add_unit_screen.dart';
import 'edit_unit_screen.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnitProvider>().fetchUnits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daireler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UnitProvider>().fetchUnits(),
          ),
        ],
      ),
      body: Consumer<UnitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchUnits(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (provider.units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apartment, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Henüz daire eklenmemiş'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddUnit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Daire Ekle'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.units.length,
            itemBuilder: (context, index) {
              final unit = provider.units[index];
              return _buildUnitCard(unit);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddUnit,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUnitCard(Unit unit) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.apartment, color: Colors.blue),
        ),
        title: Text(
          unit.fullAddress,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unit.ownerName != null) ...[
              const SizedBox(height: 4),
              Text('Malik: ${unit.ownerName}'),
            ],
            if (unit.shareRatio != null) ...[
              const SizedBox(height: 4),
              Text('Pay Oranı: ${unit.shareRatio}'),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, unit),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Düzenle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Unit unit) async {
    switch (action) {
      case 'edit':
        _navigateToEditUnit(unit);
        break;
      case 'delete':
        _deleteUnit(unit);
        break;
    }
  }

  void _navigateToAddUnit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddUnitScreen()),
    );
    if (result == true && mounted) {
      Helpers.showSnackBar(context, 'Daire başarıyla eklendi');
    }
  }

  void _navigateToEditUnit(Unit unit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditUnitScreen(unit: unit)),
    );
    if (result == true && mounted) {
      Helpers.showSnackBar(context, 'Daire başarıyla güncellendi');
    }
  }

  void _deleteUnit(Unit unit) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Daireyi Sil',
      message: '${unit.fullAddress} adresini silmek istediğinizden emin misiniz?',
    );

    if (confirmed && mounted) {
      final provider = context.read<UnitProvider>();
      final success = await provider.deleteUnit(unit.id!);
      
      if (success && mounted) {
        Helpers.showSnackBar(context, 'Daire başarıyla silindi');
      } else if (mounted) {
        Helpers.showSnackBar(context, provider.error ?? 'Bir hata oluştu', isError: true);
      }
    }
  }
}
