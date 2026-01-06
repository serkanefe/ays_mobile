import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/owner_model.dart';
import '../providers/owner_provider.dart';
import '../core/utils/helpers.dart';

class OwnerFormScreen extends StatefulWidget {
  final Owner? owner;

  const OwnerFormScreen({super.key, this.owner});

  @override
  State<OwnerFormScreen> createState() => _OwnerFormScreenState();
}

class _OwnerFormScreenState extends State<OwnerFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _identityController;
  late TextEditingController _shareRatioController;
  late TextEditingController _unitNameController;
  late TextEditingController _tenantNameController;
  late TextEditingController _tenantEmailController;

  String _ownerType = 'PERSON';
  String _unitType = 'Mesken';
  String _role = 'Malik';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.owner?.fullName ?? '');
    _emailController = TextEditingController(text: widget.owner?.email ?? '');
    _passwordController = TextEditingController(text: widget.owner?.password ?? '');
    _phoneController = TextEditingController(text: widget.owner?.phone ?? '');
    _identityController = TextEditingController(text: widget.owner?.identityNumber ?? '');
    _shareRatioController = TextEditingController(
      text: widget.owner?.shareRatio?.toString() ?? '',
    );
    _unitNameController = TextEditingController(text: widget.owner?.unitName ?? '');
    _tenantNameController = TextEditingController(text: widget.owner?.tenantName ?? '');
    _tenantEmailController = TextEditingController(text: widget.owner?.tenantEmail ?? '');
    
    _ownerType = widget.owner?.ownerType ?? 'PERSON';
    _unitType = widget.owner?.unitType ?? 'Mesken';
    _role = widget.owner?.role ?? 'Malik';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _identityController.dispose();
    _shareRatioController.dispose();
    _unitNameController.dispose();
    _tenantNameController.dispose();
    _tenantEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<OwnerProvider>();
      
      final ownerData = {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'phone': _phoneController.text.trim(),
        'identity_number': _identityController.text.trim(),
        'share_ratio': double.tryParse(_shareRatioController.text),
        'unit_name': _unitNameController.text.trim(),
        'unit_type': _unitType,
        'owner_type': _ownerType,
        'role': _role,
        'tenant_name': _tenantNameController.text.trim(),
        'tenant_email': _tenantEmailController.text.trim(),
      };

      bool success;
      if (widget.owner == null) {
        success = await provider.createOwner(ownerData);
      } else {
        success = await provider.updateOwner(widget.owner!.id!, ownerData);
      }

      if (success && mounted) {
        Helpers.showSnackBar(context, 'İşlem başarılı!');
        Navigator.pop(context);
      } else if (mounted) {
        Helpers.showSnackBar(
          context,
          provider.error ?? 'Bir hata oluştu',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.owner == null ? 'Malik Ekle' : 'Malik Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 40),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // === MALIK BİLGİLERİ ===
              const Text(
                'Malik Bilgileri',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Malik Türü
              DropdownButtonFormField<String>(
                initialValue: _ownerType,
                decoration: const InputDecoration(
                  labelText: 'Malik Türü',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'PERSON', child: Text('Gerçek Kişi')),
                  DropdownMenuItem(value: 'COMPANY', child: Text('Tüzel Kişi')),
                ],
                onChanged: (value) {
                  setState(() => _ownerType = value ?? 'PERSON');
                },
              ),
              const SizedBox(height: 16),

              // Ad Soyad
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Malik Adı Soyadı',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Helpers.validateRequired(value, 'Malik Adı Soyadı'),
              ),
              const SizedBox(height: 16),

              // E-posta
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Mail Adresi',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Helpers.validateEmail,
              ),
              const SizedBox(height: 16),

              // Şifre
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre (Giriş İçin)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) => Helpers.validateRequired(value, 'Şifre'),
              ),
              const SizedBox(height: 16),

              // Telefon
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // T.C. / Vergi No
              TextFormField(
                controller: _identityController,
                decoration: const InputDecoration(
                  labelText: 'T.C. / Vergi No',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Helpers.validateRequired(value, 'T.C. / Vergi No'),
              ),
              const SizedBox(height: 16),

              // Rol
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Rolü',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Yönetici', child: Text('Yönetici')),
                  DropdownMenuItem(value: 'Yönetici Yardımcısı', child: Text('Yönetici Yardımcısı')),
                  DropdownMenuItem(value: 'Denetci', child: Text('Denetci')),
                  DropdownMenuItem(value: 'Malik', child: Text('Malik')),
                ],
                onChanged: (value) {
                  setState(() => _role = value ?? 'Malik');
                },
              ),
              const SizedBox(height: 32),

              // === DAİRE BİLGİLERİ ===
              const Text(
                'Daire Bilgileri',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Daire No
              TextFormField(
                controller: _unitNameController,
                decoration: const InputDecoration(
                  labelText: 'Daire No',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Helpers.validateRequired(value, 'Daire No'),
              ),
              const SizedBox(height: 16),

              // Daire Tipi
              DropdownButtonFormField<String>(
                initialValue: _unitType,
                decoration: const InputDecoration(
                  labelText: 'Daire Tipi',
                  prefixIcon: Icon(Icons.apartment),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Mesken', child: Text('Mesken')),
                  DropdownMenuItem(value: 'İşyeri', child: Text('İşyeri')),
                ],
                onChanged: (value) {
                  setState(() => _unitType = value ?? 'Mesken');
                },
              ),
              const SizedBox(height: 16),

              // Arsa Payı
              TextFormField(
                controller: _shareRatioController,
                decoration: const InputDecoration(
                  labelText: 'Arsa Payı (%)',
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                  hintText: '0-100 arası',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final num = double.tryParse(value);
                    if (num == null) {
                      return 'Geçerli bir sayı girin';
                    }
                    if (num < 0 || num > 100) {
                      return 'Değer 0-100 arasında olmalıdır';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // === KİRACı BİLGİLERİ ===
              const Text(
                'Kiracı Bilgileri (İsteğe Bağlı)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Kiracı Adı
              TextFormField(
                controller: _tenantNameController,
                decoration: const InputDecoration(
                  labelText: 'Kiracı Adı',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Kiracı E-posta
              TextFormField(
                controller: _tenantEmailController,
                decoration: const InputDecoration(
                  labelText: 'Kiracı Mail Adresi',
                  prefixIcon: Icon(Icons.mail),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(widget.owner == null ? Icons.add : Icons.save),
                  onPressed: _handleSave,
                  label: Text(widget.owner == null ? 'Malik Ekle' : 'Güncelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

