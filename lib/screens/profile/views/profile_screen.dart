import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../services/sync_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    
    final success = await SyncService.instance.syncAll();
    
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Synchronisation réussie !" : "Échec de la synchronisation.",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mon Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=User&background=8E2DE2&color=fff"),
            ),
            const SizedBox(height: defaultPadding),
            const Text(
              "Vendeur Mobile",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Boutique App Sync",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: defaultPadding * 2),
            
            _buildProfileItem(
              icon: Icons.sync,
              title: "Synchroniser les données",
              subtitle: "Envoyer les ventes, cotisations et dépenses",
              trailing: _isSyncing 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isSyncing ? null : _handleSync,
            ),
            
            const SizedBox(height: defaultPadding),
            _buildProfileItem(
              icon: Icons.settings_outlined,
              title: "Paramètres",
              subtitle: "Configuration de l'application",
              onTap: () {},
            ),
            
            const SizedBox(height: defaultPadding),
            _buildProfileItem(
              icon: Icons.help_outline,
              title: "Aide & Support",
              subtitle: "FAQ et contact",
              onTap: () {},
            ),
            
            const SizedBox(height: defaultPadding * 2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(defaultPadding),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Déconnexion"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
