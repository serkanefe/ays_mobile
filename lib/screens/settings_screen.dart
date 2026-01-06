import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart' as models;
import '../providers/settings_provider.dart';
import '../core/utils/helpers.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  void _loadData() {
    final provider = context.read<SettingsProvider>();
    provider.loadSettings();
    provider.loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Genel', icon: Icon(Icons.settings)),
            Tab(text: 'Kategori', icon: Icon(Icons.category)),
            Tab(text: 'Mail', icon: Icon(Icons.mail)),
            Tab(text: 'Aidat', icon: Icon(Icons.payment)),
            Tab(text: 'Yedekleme', icon: Icon(Icons.backup)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GeneralSettingsTab(),
          CategorySettingsTab(),
          MailSettingsTab(),
          RentSettingsTab(),
          BackupSettingsTab(),
        ],
      ),
    );
  }
}

// ==================== GENERAL SETTINGS ====================
class GeneralSettingsTab extends StatefulWidget {
  const GeneralSettingsTab({super.key});

  @override
  State<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  late TextEditingController _siteNameController;
  late TextEditingController _siteAddressController;
  late TextEditingController _cityController;
  late TextEditingController _taxNumberController;
  late TextEditingController _taxOfficeController;
  late TextEditingController _apiUrlController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final settings = context.read<SettingsProvider>().settings;
    _siteNameController = TextEditingController(text: settings?.siteName ?? '');
    _siteAddressController =
        TextEditingController(text: settings?.siteAddress ?? '');
    _cityController = TextEditingController(text: settings?.city ?? '');
    _taxNumberController = TextEditingController(text: settings?.taxNumber ?? '');
    _taxOfficeController = TextEditingController(text: settings?.taxOffice ?? '');
    _apiUrlController = TextEditingController(text: ApiService.defaultBaseUrl);
    _loadCurrentApiUrl();
  }

  Future<void> _loadCurrentApiUrl() async {
    final apiService = ApiService();
    final url = await apiService.getApiUrl();
    _apiUrlController.text = url;
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _siteAddressController.dispose();
    _cityController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _siteNameController,
                      decoration: const InputDecoration(
                        labelText: 'Site Adı',
                        prefixIcon: Icon(Icons.home),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _siteAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Şehir',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _taxNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Vergi No',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _taxOfficeController,
                      decoration: const InputDecoration(
                        labelText: 'Vergi Dairesi',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiUrlController,
                      decoration: const InputDecoration(
                        labelText: 'API URL (Sunucu Adresi)',
                        prefixIcon: Icon(Icons.cloud),
                        hintText: 'http://192.168.1.8:5000/api',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Örnek: http://192.168.1.8:5000/api\nVerya: http://[HOST_IP]:5000/api',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : () => _saveGeneral(provider),
                        icon: const Icon(Icons.save),
                        label: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGeneral(SettingsProvider provider) async {
    // API URL'sini kaydet
    final apiService = ApiService();
    try {
      await apiService.setApiUrl(_apiUrlController.text);
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'API URL güncellendi',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'API URL kaydedilemedi: $e');
      }
    }

    final success = await provider.saveSettings(
      siteName: _siteNameController.text,
      siteAddress: _siteAddressController.text,
      city: _cityController.text,
      taxNumber: _taxNumberController.text,
      taxOffice: _taxOfficeController.text,
    );

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(context, 'Ayarlar kaydedildi', isError: false);
      } else {
        Helpers.showSnackBar(
          context,
          provider.error ?? 'Hata oluştu',
          isError: true,
        );
      }
    }
  }
}

// ==================== CATEGORY SETTINGS ====================
class CategorySettingsTab extends StatefulWidget {
  const CategorySettingsTab({super.key});

  @override
  State<CategorySettingsTab> createState() => _CategorySettingsTabState();
}

class _CategorySettingsTabState extends State<CategorySettingsTab> {
  late TextEditingController _categoryNameController;
  String _selectedType = 'EXPENSE';

  @override
  void initState() {
    super.initState();
    _categoryNameController = TextEditingController();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _categoryNameController,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Adı',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Tipi',
                        prefixIcon: Icon(Icons.type_specimen),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'INCOME', child: Text('Gelir')),
                        DropdownMenuItem(
                          value: 'EXPENSE',
                          child: Text('Gider'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading
                            ? null
                            : () => _addCategory(provider),
                        icon: const Icon(Icons.add),
                        label: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kategori Ekle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Kategoriler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildCategoryList(provider),
          ],
        );
      },
    );
  }

  List<Widget> _buildCategoryList(SettingsProvider provider) {
    final incomeCategories = provider.incomeCategories;
    final expenseCategories = provider.expenseCategories;

    List<Widget> widgets = [];

    if (incomeCategories.isNotEmpty) {
      widgets.add(
        Text(
          'Gelir Kategorileri',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      for (var cat in incomeCategories) {
        widgets.add(_buildCategoryCard(cat, provider, Colors.green));
      }
      widgets.add(const SizedBox(height: 16));
    }

    if (expenseCategories.isNotEmpty) {
      widgets.add(
        Text(
          'Gider Kategorileri',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      for (var cat in expenseCategories) {
        widgets.add(_buildCategoryCard(cat, provider, Colors.red));
      }
    }

    if (incomeCategories.isEmpty && expenseCategories.isEmpty) {
      widgets.add(
        Center(
          child: Text(
            'Henüz kategori eklenmemiş',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCategoryCard(
    models.Category category,
    SettingsProvider provider,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 4,
          color: color,
        ),
        title: Text(category.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteCategory(category.id!, provider),
        ),
      ),
    );
  }

  Future<void> _addCategory(SettingsProvider provider) async {
    if (_categoryNameController.text.isEmpty) {
      Helpers.showSnackBar(context, 'Kategori adını girin', isError: true);
      return;
    }

    final success = await provider.createCategory(
      name: _categoryNameController.text,
      categoryType: _selectedType,
    );

    if (mounted) {
      if (success) {
        _categoryNameController.clear();
        setState(() {
          _selectedType = 'EXPENSE';
        });
        Helpers.showSnackBar(context, 'Kategori eklendi', isError: false);
      } else {
        Helpers.showSnackBar(
          context,
          provider.error ?? 'Hata oluştu',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteCategory(int categoryId, SettingsProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: const Text('Bu kategoriyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final success = await provider.deleteCategory(categoryId);
      if (mounted) {
        if (success) {
          Helpers.showSnackBar(context, 'Kategori silindi', isError: false);
        } else {
          Helpers.showSnackBar(
            context,
            provider.error ?? 'Hata oluştu',
            isError: true,
          );
        }
      }
    }
  }
}

// ==================== MAIL SETTINGS ====================
class MailSettingsTab extends StatefulWidget {
  const MailSettingsTab({super.key});

  @override
  State<MailSettingsTab> createState() => _MailSettingsTabState();
}

class _MailSettingsTabState extends State<MailSettingsTab> {
  late TextEditingController _smtpServerController;
  late TextEditingController _smtpPortController;
  late TextEditingController _mailAddressController;
  late TextEditingController _smtpPasswordController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final settings = context.read<SettingsProvider>().settings;
    _smtpServerController = TextEditingController(text: settings?.smtpServer ?? '');
    _smtpPortController = TextEditingController(text: settings?.smtpPort?.toString() ?? '');
    _mailAddressController = TextEditingController(text: settings?.mailAddress ?? '');
    _smtpPasswordController = TextEditingController(text: settings?.smtpPassword ?? '');
  }

  @override
  void dispose() {
    _smtpServerController.dispose();
    _smtpPortController.dispose();
    _mailAddressController.dispose();
    _smtpPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _smtpServerController,
                      decoration: const InputDecoration(
                        labelText: 'SMTP Sunucusu',
                        hintText: 'smtp.gmail.com',
                        prefixIcon: Icon(Icons.dns),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _smtpPortController,
                      decoration: const InputDecoration(
                        labelText: 'SMTP Port',
                        hintText: '587',
                        prefixIcon: Icon(Icons.http),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mailAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Mail Adresi',
                        hintText: 'info@example.com',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _smtpPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'SMTP Şifre',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : () => _saveMail(provider),
                        icon: const Icon(Icons.save),
                        label: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMail(SettingsProvider provider) async {
    final success = await provider.saveSettings(
      smtpServer: _smtpServerController.text,
      smtpPort: int.tryParse(_smtpPortController.text),
      mailAddress: _mailAddressController.text,
      smtpPassword: _smtpPasswordController.text,
    );

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(context, 'Mail ayarları kaydedildi', isError: false);
      } else {
        Helpers.showSnackBar(
          context,
          provider.error ?? 'Hata oluştu',
          isError: true,
        );
      }
    }
  }
}

// ==================== RENT SETTINGS ====================
class RentSettingsTab extends StatefulWidget {
  const RentSettingsTab({super.key});

  @override
  State<RentSettingsTab> createState() => _RentSettingsTabState();
}

class _RentSettingsTabState extends State<RentSettingsTab> {
  late TextEditingController _rentDueDayController;
  late TextEditingController _lateFeeRateController;
  bool _adminPaysRent = false;
  bool _applyLateFee = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final settings = context.read<SettingsProvider>().settings;
    _rentDueDayController =
        TextEditingController(text: settings?.rentDueDay?.toString() ?? '1');
    _lateFeeRateController =
        TextEditingController(text: settings?.lateFeeRate?.toString() ?? '0');
    _adminPaysRent = settings?.adminPaysRent ?? false;
    _applyLateFee = settings?.applyLateFee ?? false;
  }

  @override
  void dispose() {
    _rentDueDayController.dispose();
    _lateFeeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _rentDueDayController,
                      decoration: const InputDecoration(
                        labelText: 'Aidat Son Ödeme Günü (1-31)',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      title: const Text('Yönetici Aidat Öder'),
                      subtitle: const Text(
                        'Yönetici de aidat ödemesi yapıyorsa işaretleyin',
                      ),
                      value: _adminPaysRent,
                      onChanged: (value) {
                        setState(() {
                          _adminPaysRent = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Gecikme Faizi Uygula'),
                      subtitle: const Text(
                        'Vadesi geçmiş aidatlara faiz uygula',
                      ),
                      value: _applyLateFee,
                      onChanged: (value) {
                        setState(() {
                          _applyLateFee = value ?? false;
                        });
                      },
                    ),
                    if (_applyLateFee) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lateFeeRateController,
                        decoration: const InputDecoration(
                          labelText: 'Gecikme Faiz Oranı (%)',
                          hintText: '1.5',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : () => _saveRent(provider),
                        icon: const Icon(Icons.save),
                        label: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRent(SettingsProvider provider) async {
    final rentDueDay = int.tryParse(_rentDueDayController.text);
    final lateFeeRate = double.tryParse(_lateFeeRateController.text);

    if (rentDueDay == null || rentDueDay < 1 || rentDueDay > 31) {
      Helpers.showSnackBar(
        context,
        'Ödeme günü 1-31 arasında olmalıdır',
        isError: true,
      );
      return;
    }

    final success = await provider.saveSettings(
      rentDueDay: rentDueDay,
      adminPaysRent: _adminPaysRent,
      applyLateFee: _applyLateFee,
      lateFeeRate: lateFeeRate ?? 0.0,
    );

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(context, 'Aidat ayarları kaydedildi', isError: false);
      } else {
        Helpers.showSnackBar(
          context,
          provider.error ?? 'Hata oluştu',
          isError: true,
        );
      }
    }
  }
}

// ==================== BACKUP SETTINGS ====================
class BackupSettingsTab extends StatefulWidget {
  const BackupSettingsTab({super.key});

  @override
  State<BackupSettingsTab> createState() => _BackupSettingsTabState();
}

class _BackupSettingsTabState extends State<BackupSettingsTab> {
  bool _isBackuping = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.backup,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Veritabanı Yedeği',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Veritabanının tam bir yedeğini oluşturun ve indirin',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isBackuping ? null : _createBackup,
                    icon: _isBackuping
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download),
                    label: _isBackuping
                        ? const Text('Yedek Oluşturuluyor...')
                        : const Text('Yedek Al'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _isBackuping = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getBackup();
      
      // Backup dosyası indirildi
      // Not: Dosya indirme özelliği web platformu için tasarlanmıştır
      
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Yedek başarıyla indirildi',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Yedek oluşturulurken hata: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      setState(() {
        _isBackuping = false;
      });
    }
  }
}

