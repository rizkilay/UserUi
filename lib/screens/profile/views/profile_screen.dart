import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour masquer la barre d'état (optionnel)
import '../../../constants.dart'; // Assurez-vous que ce chemin est correct
import '../../../services/sync_service.dart'; // Assurez-vous que ce chemin est correct

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
    // Facultatif : Masquer la barre d'état pour un look plus immersif
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fond légèrement grisé
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildUpgradeCard(),
            _buildBronzeProgressCard(),
            _buildMenuSection(
              title: "FONCTIONS PRINCIPALES",
              items: [
                _MenuItem(
                  icon: Icons.settings,
                  title: "Paramètres",
                  color: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFE65100),
                ),
                _MenuItem(
                  icon: Icons.notifications_none_outlined,
                  title: "Confidentialité",
                  color: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFC62828),
                ),
                // Exemple d'intégration de votre fonction de synchronisation
                _MenuItem(
                  icon: Icons.sync,
                  title: "Synchroniser",
                  color: const Color(0xFFE0F7FA),
                  iconColor: const Color(0xFF006064),
                  onTap: _isSyncing ? null : _handleSync,
                  trailing: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),
            _buildMenuSection(
              title: "DONNÉES",
              items: [
                _MenuItem(
                  icon: Icons.sync,
                  title: "Synchroniser",
                  subtitle: "Ventes, cotisations et dépenses",
                  color: const Color(0xFFE8EAF6),
                  iconColor: const Color(0xFF3F51B5),
                  onTap: _isSyncing ? null : _handleSync,
                  isSync: true,
                  isSyncing: _isSyncing,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAdvancedSettingsButton(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  Widget _buildUpgradeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A73E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rate, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Text(
                "iCI LE NOM DE L'ENTREPRISE",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text("Code"),
          ),
        ],
      ),
    );
  }

  Widget _buildBronzeProgressCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8), // Même bleu que l'app bar
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFCD7F32), // Bronze
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              "1",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nom caissier",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Row(
                  children: [
                    _buildStatItem(Icons.bolt, "10"),
                    const SizedBox(width: 8),
                    _buildStatItem(Icons.bolt, "250", color: const Color(0xFFFBC02D)), // Or
                  ],
                ),
                const SizedBox(height: 8),
                _buildProgressBar(),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.white, size: 14),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(color: color ?? Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: 0.1, // 0/30 => ~10% pour démo
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF43A047), // Vert vif
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          ...items,
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE3F2FD), // Bleu très clair
        foregroundColor: const Color(0xFF1A73E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Nous contacter",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final Color iconColor;
  final bool isSync;
  final bool isSyncing;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.iconColor,
    this.isSync = false,
    this.isSyncing = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 10)) : null,
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (isSync) {
      if (isSyncing) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("À jour", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            SizedBox(width: 4),
            Icon(Icons.verified, color: Colors.white, size: 12),
          ],
        ),
      );
    }
    return trailing ?? const Icon(Icons.arrow_forward_ios, size: 16);
  }
}