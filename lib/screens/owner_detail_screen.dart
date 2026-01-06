import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/owner_model.dart';
import '../providers/owner_provider.dart';
import '../widgets/common_widgets.dart';
import 'owner_form_screen.dart';

class OwnerDetailScreen extends StatefulWidget {
  final int ownerId;

  const OwnerDetailScreen({super.key, required this.ownerId});

  @override
  State<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends State<OwnerDetailScreen> {
  Owner? _owner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerDetail();
  }

  Future<void> _loadOwnerDetail() async {
    // Simüle edilmiş detay yükleme
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<OwnerProvider>();
    final owners = provider.owners;
    final owner = owners.firstWhere(
      (o) => o.id == widget.ownerId,
      orElse: () => Owner(
        fullName: 'Bulunamadı',
        email: '',
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _owner = owner;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Malik Detay')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_owner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Malik Detay')),
        body: const Center(child: Text('Malik bulunamadı')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Malik Detay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerFormScreen(owner: _owner),
                ),
              ).then((_) => _loadOwnerDetail());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            _owner!.fullName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _owner!.fullName,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                _owner!.ownerType == 'PERSON' ? 'Gerçek Kişi' : 'Tüzel Kişi',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StatusBadge(
                      label: _owner!.isActive ? 'Aktif' : 'Pasif',
                      color: _owner!.isActive ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İletişim Bilgileri
            const Text(
              'İletişim Bilgileri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InfoRow(label: 'E-posta', value: _owner!.email),
            if (_owner!.phone != null)
              InfoRow(label: 'Telefon', value: _owner!.phone!),
            const SizedBox(height: 16),

            // Kimlik Bilgileri
            if (_owner!.identityNumber != null) ...[
              const Text(
                'Kimlik Bilgileri',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InfoRow(label: 'T.C. / Vergi No', value: _owner!.identityNumber!),
              const SizedBox(height: 16),
            ],

            // Daire Bilgileri
            if (_owner!.unitName != null) ...[
              const Text(
                'Daire Bilgileri',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InfoRow(label: 'Daire', value: _owner!.unitName!),
              if (_owner!.shareRatio != null)
                InfoRow(
                  label: 'Arsa Payı',
                  value: '${_owner!.shareRatio}%',
                ),
              const SizedBox(height: 16),
            ],

            // Mali Özet
            if (_owner!.totalRent != null) ...[
              const Text(
                'Mali Özet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Toplam Aidat:'),
                          Text(
                            '₺${_owner!.totalRent?.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Toplam Ödeme:'),
                          Text(
                            '₺${_owner!.totalPaid?.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kalan Borç:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₺${_owner!.remainingDebt?.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _owner!.remainingDebt! > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
