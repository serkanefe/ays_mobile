import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/announcement_provider.dart';
import '../core/utils/helpers.dart';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyuru Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Duyuru başlığını girin',
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 100,
                validator: (value) => Helpers.validateRequired(value, 'Başlık'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'İçerik',
                  hintText: 'Duyuru içeriğini girin',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                maxLength: 1000,
                validator: (value) => Helpers.validateRequired(value, 'İçerik'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Duyuruyu Sabitle'),
                subtitle: const Text('Sabitlenmiş duyurular üstte gösterilir'),
                value: _isPinned,
                onChanged: (value) {
                  setState(() {
                    _isPinned = value;
                  });
                },
                secondary: Icon(
                  _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: _isPinned ? Colors.orange : null,
                ),
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
                    : const Text('Yayınla'),
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

    final provider = context.read<AnnouncementProvider>();
    final success = await provider.createAnnouncement(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      isPinned: _isPinned,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      Helpers.showSnackBar(
        context,
        provider.error ?? 'Duyuru eklenemedi',
        isError: true,
      );
    }
  }
}
