import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.name);
    _surnameController = TextEditingController(text: auth.surname);
    _nicknameController = TextEditingController(text: auth.nickname);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    context.read<AuthProvider>().updateProfile(
      _nameController.text,
      _surnameController.text,
      _nicknameController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile saved successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _clearPersonalData() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    await context.read<AuthProvider>().clearProfileData();

    _nameController.clear();
    _surnameController.clear();
    _nicknameController.text = 'Student';

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Personal data deleted'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // --- HELPER DECORAZIONE AGGIORNATO ---
  InputDecoration _customInputDecoration(
    String label,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return InputDecoration(
      labelText: label,
      // Ingrandito il testo della label
      labelStyle: const TextStyle(fontSize: 16),
      // Ingrandita l'icona e aggiunto un po' di spazio laterale per farla respirare
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Icon(icon, color: colorScheme.primary, size: 26),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withAlpha(50),
      // Rimosso isDense: true
      // Aumentato il padding interno verticale (20) e orizzontale (20)
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          16,
        ), // Bordi leggermente più morbidi
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 8.0,
                  bottom: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- AVATAR ---
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.tertiary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(50),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.manage_accounts_rounded,
                          size: 44,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- TITOLO E DESCRIZIONE ---
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Manage your personal data and preferences",
                      style: TextStyle(
                        fontSize: 16, // Leggermente più grande
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- CAMPI DI TESTO AGGIORNATI ---
                    TextFormField(
                      controller: _nicknameController,
                      textInputAction: TextInputAction.next,
                      // Font size aumentato a 18 per il testo digitato
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _customInputDecoration(
                        'Nickname',
                        Icons.alternate_email_rounded,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(height: 16), // Spaziatura aumentata

                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _customInputDecoration(
                        'Name',
                        Icons.person_outline_rounded,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _surnameController,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _customInputDecoration(
                        'Surname',
                        Icons.fingerprint_outlined,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ), // Spaziatura aumentata prima del bottone
                    // Pulsante Salva (ingrandito in altezza a 56)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _saveProfile,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ), // Border radius coordinato coi textfield
                        ),
                        child: const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Ho ridotto il SizedBox fisso per lasciare che il layout si adatti meglio
                    // se i campi sopra sono più grandi
                    const SizedBox(height: 48),

                    // --- PRIVACY & DATA SECTION (Fondo Schermo) ---
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Ingrandito
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(
                            color: colorScheme.error.withAlpha(80),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.person_remove_rounded, size: 22),
                        label: const Text(
                          'DELETE PERSONAL DATA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: _clearPersonalData,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 56, // Ingrandito
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.onErrorContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 22),
                        label: const Text(
                          'DISCONNECT FROM IMPACT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: () => _handleLogout(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
