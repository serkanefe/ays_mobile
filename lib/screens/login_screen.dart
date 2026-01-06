import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/utils/helpers.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final authProvider = context.read<AuthProvider>();
    final saved = await authProvider.loadSavedCredentials();
    if (saved != null) {
      setState(() {
        _emailController.text = saved['email'] ?? '';
        _passwordController.text = saved['password'] ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else if (mounted) {
        Helpers.showSnackBar(
          context,
          authProvider.error ?? 'Giriş başarısız',
          isError: true,
        );
      }
    }
  }

  Future<void> _showApiSettingsDialog() async {
    final apiService = ApiService();
    final currentUrl = await apiService.getApiUrl();
    final apiUrlController = TextEditingController(text: currentUrl);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'http://192.168.1.8:5000/api',
                prefixIcon: Icon(Icons.cloud),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            const Text(
              'Örnek: http://192.168.1.8:5000/api',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (apiUrlController.text.isNotEmpty) {
                await apiService.setApiUrl(apiUrlController.text);
                if (mounted) {
                  Navigator.pop(context);
                  Helpers.showSnackBar(
                    context,
                    'API URL kaydedildi. Tekrar dene.',
                    isError: false,
                  );
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apartment,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Apartman Yönetim Sistemi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Helpers.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: Helpers.validatePassword,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Beni Hatırla'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (context, provider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _handleLogin,
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Giriş Yap'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _showApiSettingsDialog,
                    icon: const Icon(Icons.settings),
                    label: const Text('API Ayarlarını Düzenle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
