import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/analytics_provider.dart';
import '../utils/dashboard_helpers.dart';
import '../utils/settings_components.dart';
import 'login_page.dart';

/// Manages the user's local identity, system connections, and developer tools.
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

    _nameController = TextEditingController(text: _initialName)
      ..addListener(_checkForChanges);
    _surnameController = TextEditingController(text: _initialSurname)
      ..addListener(_checkForChanges);
    _nicknameController = TextEditingController(text: _initialNickname)
      ..addListener(_checkForChanges);
  }

  @override
  void dispose() {
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
  // CORE DOMAIN ACTIONS
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

    final authProvider = context.read<AuthProvider>();
    final bool? confirm = await _showWarningDialog(
      title: 'Purge Identity Data?',
      content:
          'This will irreversibly erase your local personal information. Proceed?',
      confirmText: 'PURGE DATA',
    );

    if (confirm != true || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      await authProvider.clearProfileData();

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

  Future<void> _handleLogout() async {
    if (_isProcessing) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.heavyImpact();

    final analyticsProvider = context.read<AnalyticsProvider>();
    final authProvider = context.read<AuthProvider>();

    final bool? confirm = await _showWarningDialog(
      title: 'Disconnect Session?',
      content: 'You will be logged out of the Impact framework.',
      confirmText: 'DISCONNECT',
    );

    if (confirm != true || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      await analyticsProvider.saveWorkloadToDisk();
      await authProvider.logout();
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
  // UI FEEDBACK HELPERS
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
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
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // VIEW RENDERER
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
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // --- AMBIENT GLOW SYSTEM ---
              Positioned(
                top: -150,
                left: -100,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.tertiary.withAlpha(45),
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
                  // --- HARMONIZED SECONDARY APP BAR ---
                  SliverAppBar(
                    pinned: true,
                    stretch: true,
                    expandedHeight:
                        110.0, // Ridotto per bilanciare lo spazio negativo
                    toolbarHeight: 64.0,
                    backgroundColor: colorScheme.surface.withAlpha(160),
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
                        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: FlexibleSpaceBar(
                          stretchModes: const [StretchMode.zoomBackground],
                          centerTitle:
                              true, // Centra il testo per bilanciare il pulsante indietro
                          titlePadding: const EdgeInsets.only(bottom: 16.0),
                          title: Text(
                            'Identity',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          background: const SizedBox(),
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 64.0),
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

                        // --- PERSONAL DATA FORM ---
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            'PERSONAL DATA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Form(
                          key: _formKey,
                          child: SettingsGroup(
                            children: [
                              SettingsTextField(
                                label: 'Nickname',
                                icon: Icons.alternate_email_rounded,
                                controller: _nicknameController,
                                action: TextInputAction.next,
                                isEnabled: !_isProcessing,
                              ),
                              SettingsTextField(
                                label: 'First Name',
                                icon: Icons.person_outline_rounded,
                                controller: _nameController,
                                action: TextInputAction.next,
                                isEnabled: !_isProcessing,
                              ),
                              SettingsTextField(
                                label: 'Last Name',
                                icon: Icons.fingerprint_rounded,
                                controller: _surnameController,
                                action: TextInputAction.done,
                                isEnabled: !_isProcessing,
                                isLast: true,
                                onSubmitted: (_) => _saveProfile(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- SAVE BUTTON ---
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _hasUnsavedChanges ? 1.0 : 0.4,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _saveProfile,
                              child: _isProcessing
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('SAVE CHANGES'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // --- DEVELOPER TOOLS (SIMULATOR) ---
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            'DEVELOPER TOOLS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ),
                        const SettingsGroup(children: [SimulatorSettingsRow()]),
                        const SizedBox(height: 48),

                        // --- SYSTEM SETTINGS ---
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            'SYSTEM SETTINGS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SettingsGroup(
                          children: [
                            SettingsActionRow(
                              label: 'Purge Identity Data',
                              icon: Icons.delete_forever_rounded,
                              onTap: _isProcessing ? null : _clearPersonalData,
                            ),
                            SettingsActionRow(
                              label: 'Disconnect Server',
                              icon: Icons.logout_rounded,
                              onTap: _isProcessing ? null : _handleLogout,
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
