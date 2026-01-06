import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class KasaHareketleriRaporuScreen extends StatelessWidget {
  const KasaHareketleriRaporuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa Hareketleri Raporu'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyState(
          message: 'Kasa hareketleri raporu henüz hazır değil. Buraya rapor filtreleri ve tablo görünecek.',
          icon: Icons.receipt_long,
        ),
      ),
    );
  }
}
