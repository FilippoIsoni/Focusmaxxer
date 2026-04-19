import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profilo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.primary.withAlpha(25),
                  child: Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Studente Pro',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'studente@universita.it', // In futuro potrai prenderlo da AuthProvider
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          Text(
            'CONNESSIONI BIOMETRICHE',
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.watch_rounded,
            title: 'Sorgente Dati',
            subtitle: 'Simulatore Wearable Attivo',
            colorScheme: colorScheme,
            onTap: () {},
          ),

          const SizedBox(height: 32),
          Text(
            'PREFERENZE',
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifiche di Sessione',
            subtitle: 'Vibrazione aptica abilitata',
            colorScheme: colorScheme,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tema Scuro',
            subtitle: 'Forzato dal sistema',
            colorScheme: colorScheme,
            onTap: () {},
          ),

          const SizedBox(height: 48),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withAlpha(50)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'DISCONNETTI',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();

              // 1. Scriviamo su disco che l'utente è uscito
              await context.read<AuthProvider>().logout();

              // 2. Sicurezza Flutter per il contesto
              if (!context.mounted) return;

              // 3. Importante: pushAndRemoveUntil distrugge tutto l'albero di navigazione
              // (inclusa la ProfilePage e la HomeDashboard) e piazza la LoginPage come radice.
              // Importa 'login_page.dart' in cima al file se non c'è già!
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (Route<dynamic> route) => false, 
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(25)),
      ),
      tileColor: colorScheme.surface,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
