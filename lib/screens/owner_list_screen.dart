import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/owner_provider.dart';
import '../widgets/common_widgets.dart';
import 'owner_detail_screen.dart';
import 'owner_form_screen.dart';

class OwnerListScreen extends StatefulWidget {
  const OwnerListScreen({super.key});

  @override
  State<OwnerListScreen> createState() => _OwnerListScreenState();
}

class _OwnerListScreenState extends State<OwnerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchOwners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malik Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OwnerProvider>().fetchOwners(),
          ),
        ],
      ),
      body: Consumer<OwnerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return ErrorView(
              message: provider.error!,
              onRetry: () => provider.fetchOwners(),
            );
          }
          if (provider.owners.isEmpty) {
            return const EmptyState(
              message: 'Kayıtlı malik yok',
              icon: Icons.people_outline,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.owners.length,
            itemBuilder: (context, index) {
              final owner = provider.owners[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OwnerDetailScreen(ownerId: owner.id!),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      (owner.fullName.isNotEmpty ? owner.fullName[0] : '?').toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    owner.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner.email, overflow: TextOverflow.ellipsis),
                      if (owner.unitName != null)
                        Text(
                          'Daire: ${owner.unitName} (${owner.unitType ?? 'Mesken'})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'detail') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OwnerDetailScreen(ownerId: owner.id!),
                          ),
                        );
                      } else if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OwnerFormScreen(owner: owner),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, owner.id!);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 12),
                            Text('Detay'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OwnerFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int ownerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Malik Sil'),
        content: const Text('Bu maliki silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<OwnerProvider>().deleteOwner(ownerId);
              Navigator.pop(context);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
