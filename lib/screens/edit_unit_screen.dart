import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit_model.dart';
import '../providers/unit_provider.dart';
import '../providers/owner_provider.dart';
import '../core/utils/helpers.dart';

class EditUnitScreen extends StatefulWidget {
  final Unit unit;

  const EditUnitScreen({super.key, required this.unit});

  @override
  State<EditUnitScreen> createState() => _EditUnitScreenState();
}

class _EditUnitScreenState extends State<EditUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _blockNameController;
  late TextEditingController _unitNumberController;
  late TextEditingController _shareRatioController;
  
  int? _selectedOwnerId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _blockNameController = TextEditingController(text: widget.unit.blockName);
    _unitNumberController = TextEditingController(text: widget.unit.unitNumber);
    _shareRatioController = TextEditingController(
      text: widget.unit.shareRatio?.toString() ?? '',
    );
    _selectedOwnerId = widget.unit.ownerId;
    _isActive = widget.unit.isActive;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchOwners();
    });
  }

  @override
  void dispose() {
    _blockNameController.dispose();
    _unitNumberController.dispose();
    _shareRatioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daire Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _blockNameController,
                decoration: const InputDecoration(
                  labelText: 'Blok Adı',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => Helpers.validateRequired(value, 'Blok adı'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitNumberController,
                decoration: const InputDecoration(
                  labelText: 'Daire No',
                  prefixIcon: Icon(Icons.door_front_door),
                ),
                validator: (value) => Helpers.validateRequired(value, 'Daire no'),
              ),
              const SizedBox(height: 16),
              Consumer<OwnerProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedOwnerId,
                    decoration: const InputDecoration(
                      labelText: 'Malik',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Seçiniz'),
                      ),
                      ...provider.owners.map((owner) {
                        return DropdownMenuItem<int>(
                          value: owner.id,
                          child: Text(owner.fullName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedOwnerId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shareRatioController,
                decoration: const InputDecoration(
                  labelText: 'Pay Oranı',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktif'),
                subtitle: const Text('Daire kullanımda mı?'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final provider = context.read<UnitProvider>();
    final success = await provider.updateUnit(widget.unit.id!, {
      'block_name': _blockNameController.text.trim(),
      'unit_number': _unitNumberController.text.trim(),
      'owner_id': _selectedOwnerId,
      'share_ratio': _shareRatioController.text.isNotEmpty
          ? double.tryParse(_shareRatioController.text)
          : null,
      'is_active': _isActive,
    });

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      Helpers.showSnackBar(
        context,
        provider.error ?? 'Daire güncellenemedi',
        isError: true,
      );
    }
  }
}
