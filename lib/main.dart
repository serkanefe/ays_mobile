import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/owner_provider.dart';
import 'providers/unit_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/rent_provider.dart';
import 'screens/login_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  await initializeDateFormatting('tr_TR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OwnerProvider()),
        ChangeNotifierProvider(create: (_) => UnitProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final role = context.read<AuthProvider>().user?.role;
            return RentProvider(userRole: role)..loadAll();
          },
        ),
      ],
      child: MaterialApp(
        title: 'Apartman Yönetim Sistemi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
