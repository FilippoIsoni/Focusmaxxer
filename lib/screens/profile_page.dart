import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'home_dashboard.dart';
import '../providers/cognitive_engine_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _nicknameController;

  late String _initialName;
  late String _initialSurname;
  late String _initialNickname;

  bool _hasUnsavedChanges = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();

    _initialName = auth.name;
    _initialSurname = auth.surname;
    _initialNickname = auth.nickname;

    _nameController = TextEditingController(text: _initialName);
    _surnameController = TextEditingController(text: _initialSurname);
    _nicknameController = TextEditingController(text: _initialNickname);

    _nameController.addListener(_checkForChanges);
    _surnameController.addListener(_checkForChanges);
    _nicknameController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _surnameController.removeListener(_checkForChanges);
    _nicknameController.removeListener(_checkForChanges);

    _nameController.dispose();
    _surnameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final bool hasChanges =
        _nameController.text.trim() != _initialName ||
        _surnameController.text.trim() != _initialSurname ||
        _nicknameController.text.trim() != _initialNickname;

    if (_hasUnsavedChanges != hasChanges) {
      setState(() => _hasUnsavedChanges = hasChanges);
    }
  }

  // ==========================================
  // CORE ACTIONS
  // ==========================================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() ||
        _isProcessing ||
        !_hasUnsavedChanges) {
      if (!_hasUnsavedChanges) HapticFeedback.selectionClick();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    try {
      await context.read<AuthProvider>().updateProfile(
        _nameController.text.trim(),
        _surnameController.text.trim(),
        _nicknameController.text.trim(),
      );

      _initialName = _nameController.text.trim();
      _initialSurname = _surnameController.text.trim();
      _initialNickname = _nicknameController.text.trim();
      _checkForChanges();

      _showCustomSnackBar('Profile securely updated', isError: false);
    } catch (e) {
      _showCustomSnackBar(
        'Sync failed. Please verify connection.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _clearPersonalData() async {
    if (_isProcessing) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    final bool? confirm = await _showWarningDialog(
      title: 'Purge Identity Data?',
      content:
          'This will irreversibly erase your local personal information. Proceed?',
      confirmText: 'PURGE DATA',
    );
    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await context.read<AuthProvider>().clearProfileData();

      _initialName = '';
      _initialSurname = '';
      _initialNickname = 'Student';

      _nameController.clear();
      _surnameController.clear();
      _nicknameController.text = 'Student';
      _checkForChanges();

      _showCustomSnackBar('Identity purged successfully', isError: true);
    } catch (e) {
      _showCustomSnackBar('Critical error during deletion.', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // FIX: Rimosso il parametro BuildContext. Usa il context implicito dello State.
  Future<void> _handleLogout() async {
    if (_isProcessing) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.heavyImpact();

    final bool? confirm = await _showWarningDialog(
      title: 'Disconnect Session?',
      content: 'You will be logged out of the Impact framework.',
      confirmText: 'DISCONNECT',
    );
    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      // 1. SPEGNI IL MOTORE: Ferma i timer e pulisci la RAM della sessione
      context.read<CognitiveEngineProvider>().resetEngine();
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PremiumPageRoute(page: const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      _showCustomSnackBar('Disconnection sequence failed.', isError: true);
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ==========================================
  // UI HELPERS
  // ==========================================

  void _showCustomSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      ),
    );
  }

  Future<bool?> _showWarningDialog({
    required String title,
    required String content,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // SETTINGS PANEL BUILDERS (Premium UI)
  // ==========================================

  Widget _buildSettingsGroup({required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildTextFieldRow({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required TextInputAction action,
    bool isLast = false,
    Function(String)? onSubmitted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textInputAction: action,
                  onFieldSubmitted: onSubmitted,
                  enabled: !_isProcessing,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  cursorColor: colorScheme.primary,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                      fontSize: 13,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: InputBorder.none, // Nessun bordo pacchiano!
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 20,
            color: Colors.white.withAlpha(10),
          ),
      ],
    );
  }

  Widget _buildActionRow({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _isProcessing ? null : onTap,
      highlightColor: colorScheme.error.withAlpha(20),
      splashColor: colorScheme.error.withAlpha(30),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.error.withAlpha(220), size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error.withAlpha(220),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.error.withAlpha(100),
                  size: 20,
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              indent: 56,
              endIndent: 20,
              color: colorScheme.error.withAlpha(20),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool? confirmDiscard = await _showWarningDialog(
          title: 'Discard Changes?',
          content: 'You have unsaved identity modifications.',
          confirmText: 'DISCARD',
        );
        if (confirmDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Rilascia il cursore
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // --- AMBIENT BACKGROUND GLOW ---
              Positioned(
                top: -150,
                left: -50,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.tertiary.withAlpha(30),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),

              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- SMART SLIVER APP BAR ---
                  SliverAppBar(
                    pinned: true,
                    stretch: true,
                    expandedHeight: 120.0,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {
                        if (!_hasUnsavedChanges) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                    ),
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: FlexibleSpaceBar(
                          title: const Text(
                            'Identity',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                          centerTitle: true,
                          background: Container(
                            color: colorScheme.surface.withAlpha(160),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- CONTENT ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 64.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // --- AVATAR ---
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.tertiary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 48,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surfaceContainerHighest,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // --- SECTION: IDENTITY ---
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            'PERSONAL DATA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Form(
                          key: _formKey,
                          child: _buildSettingsGroup(
                            children: [
                              _buildTextFieldRow(
                                label: 'Nickname',
                                icon: Icons.alternate_email_rounded,
                                controller: _nicknameController,
                                action: TextInputAction.next,
                              ),
                              _buildTextFieldRow(
                                label: 'First Name',
                                icon: Icons.person_outline_rounded,
                                controller: _nameController,
                                action: TextInputAction.next,
                              ),
                              _buildTextFieldRow(
                                label: 'Last Name',
                                icon: Icons.fingerprint_rounded,
                                controller: _surnameController,
                                action: TextInputAction.done,
                                isLast: true,
                                onSubmitted: (_) => _saveProfile(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- SMART SAVE BUTTON ---
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _hasUnsavedChanges ? 1.0 : 0.4,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _saveProfile,
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isProcessing
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'SAVE CHANGES',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // --- SECTION: DANGER ZONE ---
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            'SYSTEM SETTINGS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildSettingsGroup(
                          children: [
                            _buildActionRow(
                              label: 'Purge Identity Data',
                              icon: Icons.delete_forever_rounded,
                              onTap: _clearPersonalData,
                            ),
                            _buildActionRow(
                              label: 'Disconnect Server',
                              icon: Icons.logout_rounded,
                              onTap: _handleLogout,
                              isLast: true,
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
