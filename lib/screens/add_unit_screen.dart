import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/unit_provider.dart';
import '../providers/owner_provider.dart';
import '../core/utils/helpers.dart';

class AddUnitScreen extends StatefulWidget {
  const AddUnitScreen({super.key});

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _blockNameController = TextEditingController();
  final _unitNumberController = TextEditingController();
  final _shareRatioController = TextEditingController();
  
  int? _selectedOwnerId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
        title: const Text('Daire Ekle'),
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
                  hintText: 'Örn: A Blok',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => Helpers.validateRequired(value, 'Blok adı'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitNumberController,
                decoration: const InputDecoration(
                  labelText: 'Daire No',
                  hintText: 'Örn: 5',
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
                      labelText: 'Malik (Opsiyonel)',
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
                  labelText: 'Pay Oranı (Opsiyonel)',
                  hintText: 'Örn: 100',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
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
                    : const Text('Kaydet'),
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
    final success = await provider.createUnit(
      blockName: _blockNameController.text.trim(),
      unitNumber: _unitNumberController.text.trim(),
      ownerId: _selectedOwnerId,
      shareRatio: _shareRatioController.text.isNotEmpty
          ? double.tryParse(_shareRatioController.text)
          : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      Helpers.showSnackBar(
        context,
        provider.error ?? 'Daire eklenemedi',
        isError: true,
      );
    }
  }
}
