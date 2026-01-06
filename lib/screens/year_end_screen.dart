import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/utils/helpers.dart';
import '../core/constants/app_constants.dart';

class YearEndScreen extends StatefulWidget {
  const YearEndScreen({super.key});

  @override
  State<YearEndScreen> createState() => _YearEndScreenState();
}

class _YearEndScreenState extends State<YearEndScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _summary;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.getYearEndSummary(_selectedYear);
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Helpers.showSnackBar(context, 'Özet yüklenemedi: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yıl Sonu İşlemleri'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildYearSelector(),
                  const SizedBox(height: 24),
                  if (_summary != null) ...[
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildCloseYearSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildYearSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yıl Seçin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: List.generate(5, (index) {
                final year = DateTime.now().year - index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                  });
                  _loadSummary();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_selectedYear Yılı Özeti',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildSummaryRow('Toplam Gelir', _summary!['total_income']),
            const SizedBox(height: 8),
            _buildSummaryRow('Toplam Gider', _summary!['total_expense']),
            const SizedBox(height: 8),
            _buildSummaryRow('Net Bakiye', _summary!['net_balance'], 
                isHighlight: true),
            const SizedBox(height: 16),
            _buildSummaryRow('Ödenen Aidatlar', _summary!['paid_rents']),
            const SizedBox(height: 8),
            _buildSummaryRow('Ödenmemiş Aidatlar', _summary!['unpaid_rents'],
                isError: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, dynamic value, {bool isHighlight = false, bool isError = false}) {
    Color? textColor;
    if (isHighlight) textColor = Colors.green;
    if (isError) textColor = Colors.red;

    String displayValue = value is num 
        ? Helpers.formatCurrency(value.toDouble()) 
        : value.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: isHighlight ? FontWeight.bold : null,
          ),
        ),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCloseYearSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Yıl Sonu Kapanışı',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Yıl sonu kapanışı yapmak istediğinize emin misiniz? '
              'Bu işlem geri alınamaz ve mevcut yıl arşivlenecektir.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleCloseYear,
              icon: const Icon(Icons.lock),
              label: Text('$_selectedYear Yılını Kapat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCloseYear() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Yıl Sonu Kapanışı',
      message: '$_selectedYear yılını kapatmak istediğinizden emin misiniz? '
          'Bu işlem geri alınamaz.',
      confirmText: 'Evet, Kapat',
      cancelText: 'İptal',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.closeYear(_selectedYear);
      
      if (mounted) {
        Helpers.showSnackBar(context, 'Yıl başarıyla kapatıldı');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Yıl kapatılırken hata oluştu: $e',
          isError: true,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
