import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/announcement_model.dart';
import '../providers/announcement_provider.dart';
import '../core/utils/helpers.dart';
import 'add_announcement_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().fetchAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnnouncementProvider>().fetchAnnouncements(),
          ),
        ],
      ),
      body: Consumer<AnnouncementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAnnouncements(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (provider.announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Henüz duyuru eklenmemiş'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddAnnouncement(),
                    icon: const Icon(Icons.add),
                    label: const Text('Duyuru Ekle'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.announcements.length,
            itemBuilder: (context, index) {
              final announcement = provider.announcements[index];
              return _buildAnnouncementCard(announcement);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAnnouncement,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: announcement.isPinned 
              ? Colors.orange.shade100 
              : Colors.blue.shade100,
          child: Icon(
            announcement.isPinned ? Icons.push_pin : Icons.campaign,
            color: announcement.isPinned ? Colors.orange : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                announcement.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (announcement.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SABİTLENDİ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (announcement.createdByName != null)
              Text('Yayınlayan: ${announcement.createdByName}'),
            if (announcement.createdAt != null)
              Text('Tarih: ${Helpers.formatDateTime(announcement.createdAt)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, announcement),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pin',
              child: Row(
                children: [
                  Icon(
                    announcement.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(announcement.isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              announcement.content,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Announcement announcement) async {
    switch (action) {
      case 'pin':
        _togglePin(announcement);
        break;
      case 'delete':
        _deleteAnnouncement(announcement);
        break;
    }
  }

  void _navigateToAddAnnouncement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAnnouncementScreen()),
    );
    if (result == true && mounted) {
      Helpers.showSnackBar(context, 'Duyuru başarıyla eklendi');
    }
  }

  void _togglePin(Announcement announcement) async {
    final provider = context.read<AnnouncementProvider>();
    final success = await provider.updateAnnouncement(announcement.id!, {
      'title': announcement.title,
      'content': announcement.content,
      'is_pinned': !announcement.isPinned,
      'is_active': announcement.isActive,
    });

    if (success && mounted) {
      Helpers.showSnackBar(
        context,
        announcement.isPinned ? 'Sabitleme kaldırıldı' : 'Duyuru sabitlendi',
      );
    } else if (mounted) {
      Helpers.showSnackBar(context, provider.error ?? 'Bir hata oluştu', isError: true);
    }
  }

  void _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Duyuruyu Sil',
      message: '${announcement.title} başlıklı duyuruyu silmek istediğinizden emin misiniz?',
    );

    if (confirmed && mounted) {
      final provider = context.read<AnnouncementProvider>();
      final success = await provider.deleteAnnouncement(announcement.id!);
      
      if (success && mounted) {
        Helpers.showSnackBar(context, 'Duyuru başarıyla silindi');
      } else if (mounted) {
        Helpers.showSnackBar(context, provider.error ?? 'Bir hata oluştu', isError: true);
      }
    }
  }
}
