import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'unpaid_rents_screen.dart';
import 'login_screen.dart';
import 'owner_list_screen.dart';
import 'rents_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'announcements_screen.dart';
import 'year_end_screen.dart';
import 'karar_defteri_screen.dart';
import 'isletme_defteri_screen.dart';
import 'bakim_anlasmalar_screen.dart';
import 'hazirun_cetveli_screen.dart';
import 'faaliyet_raporu_screen.dart';
import 'kasa_banka_hareketleri_screen.dart';
import 'kasa_hareketleri_raporu_screen.dart';
import 'bilanco_screen.dart';
import 'tahsilatlar_screen.dart';
import 'borc_durumu_screen.dart';
import 'daire_listesi_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _apiService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Veriler yüklenirken hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboardData,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kullanıcı bilgileri kartı
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      child: Text(
                                        user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user?.fullName ?? 'Kullanıcı',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          Text(
                                            user?.role ?? '',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // İstatistikler
                        if (_stats != null) ...[
                          Text(
                            'Genel İstatistikler',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _buildStatCard(
                                context,
                                'Toplam Daire',
                                _stats!['totalUnits']?.toString() ?? '0',
                                Icons.home,
                                Colors.blue,
                              ),
                              _buildStatCard(
                                context,
                                'Ödenmemiş Aidat',
                                _stats!['unpaidRents']?.toString() ?? '0',
                                Icons.warning,
                                Colors.orange,
                              ),
                              _buildStatCard(
                                context,
                                'Toplam Borç',
                                currencyFormat.format(_stats!['totalDebt'] ?? 0),
                                Icons.attach_money,
                                Colors.red,
                              ),
                              _buildStatCard(
                                context,
                                'Bu Ay Tahsilat',
                                currencyFormat.format(_stats!['monthlyCollection'] ?? 0),
                                Icons.trending_up,
                                Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Hızlı Erişim
                          Text(
                            'Hızlı Erişim',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildQuickAccessButton(
                            context,
                            'Ödenmemiş Aidatlar',
                            Icons.payment,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UnpaidRentsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          _buildQuickAccessButton(
                            context,
                            'Malikler',
                            Icons.people,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OwnerListScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          _buildQuickAccessButton(
                            context,
                            'Giderler',
                            Icons.receipt_long,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ExpensesScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          _buildQuickAccessButton(
                            context,
                            'Kasa/Banka',
                            Icons.account_balance_wallet,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const KasaBankaHareketleriScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          _buildQuickAccessButton(
                            context,
                            'Raporlar',
                            Icons.bar_chart,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  fontSize: 40.0,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            accountName: Text(
              user?.fullName ?? 'Kullanıcı',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(user?.email ?? ''),
          ),
          
          // Ana Sayfa
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Ana Sayfa'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          
          const Divider(),
          
          // Malikler
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Malikler'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerListScreen()),
              );
            },
          ),
          
          // Aidatlar
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Aidatlar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RentsScreen()),
              );
            },
          ),
          
          // Giderler
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Giderler'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesScreen()),
              );
            },
          ),
          
          // Kasa/Banka
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Kasa/Banka'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KasaBankaHareketleriScreen()),
              );
            },
          ),
          
          const Divider(),
          
          // Yönetim (Alt Menüler)
          ExpansionTile(
            leading: const Icon(Icons.business),
            title: const Text('Yönetim'),
            children: [
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Duyurular'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
                  );
                },
              ),
              const Divider(indent: 16),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Karar Defteri'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KararDefteriScreen()),
                  );
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('İşletme Defteri'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IsletmeDefteriScreen()),
                  );
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Bakım Anlaşmaları'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BakimAnlasmalarScreen()),
                  );
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Hazirun Cetveli'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HazirunCetveliScreen()),
                  );
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Faaliyet Raporu'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaaliyetRaporuScreen()),
                  );
                },
              ),
            ],
          ),
          
          // Raporlar (Alt Menüler)
          ExpansionTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Raporlar'),
            children: [
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Kasa Hareketleri Raporu'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KasaHareketleriRaporuScreen()),
                  );
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Bilanço'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BilancoScreen()),
                  );
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Tahsilatlar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TahsilatlarScreen()),
                  );
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Borç Durumu'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BorcDurumuScreen()),
                  );
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('Daire Listesi'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DaireListesiScreen()),
                  );
                },
              ),
            ],
          ),
          
          // Yıl Sonu İşlemleri (Ana Menü)
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Yıl Sonu İşlemleri'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const YearEndScreen()),
              );
            },
          ),
          
          const Divider(),
          
          // Ayarlar
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          
          // Çıkış Yap
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }
}
