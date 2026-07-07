import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/impact_api_service.dart';
import '../utils/dashboard_helpers.dart'; // Barrel: provides ImmersiveRoute.
import 'bootloader_screen.dart';

/// The sign-in screen.
///
/// Layer: UI. Collects credentials, delegates authentication to [AuthProvider]
/// (over [ImpactApiService]), and on success dives into the [BootloaderScreen].
/// A non-success [AuthOutcome] is translated into a specific error snackbar so
/// the failure reason is honest (bad credentials vs. no network vs. server).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- Ambient glow (decorative blob behind the content) ---
  // Unlike the other screens this is *not* the shared [AmbientGlow]: the glow
  // here is a hard-edged circle softened by a full-screen backdrop blur (see
  // below), which the gradient-based AmbientGlow would not reproduce.
  static const double _glowDiameter = 300.0;
  static const double _glowTop = 100.0;
  static const int _glowAlpha = 15; // Subtle on the dark theme.
  static const double _glowBlurSigma = 80.0; // Heavy blur turns the circle soft.

  /// Logo asset shown above the title.
  static const String _logoAsset = 'assets/focusmaxxer_ic_foreground_10e.png';

  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates the inputs, runs the login, and routes on the outcome.
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    // Ignore empty submissions with a light haptic instead of a network call.
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final outcome = await context.read<AuthProvider>().login(
        context.read<ImpactApiService>(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (outcome == AuthOutcome.success) {
        // Immersive dive into the bootloader — the system "pulls the user in".
        Navigator.of(context).pushReplacement(
          ImmersiveRoute(page: const BootloaderScreen()),
        );
        return;
      }

      setState(() => _isLoading = false);
      _showErrorSnackBar(_messageForOutcome(outcome));
    } catch (e) {
      // Unexpected failure (e.g. local storage write): keep a generic fallback.
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Something went wrong. Please try again.');
    }
  }

  /// Maps a non-success login outcome to a user-facing message, so a network
  /// problem is not mislabelled as wrong credentials.
  String _messageForOutcome(AuthOutcome outcome) {
    switch (outcome) {
      case AuthOutcome.invalidCredentials:
        return 'Invalid credentials. Please try again.';
      case AuthOutcome.networkError:
        return 'No connection. Check your network and try again.';
      case AuthOutcome.serverError:
        return 'Server error. Please try again later.';
      case AuthOutcome.success:
        return ''; // Not reachable: success is handled before this call.
    }
  }

  /// Shows an error snackbar with an inline icon in the theme's error color.
  void _showErrorSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Tap anywhere outside the fields to dismiss the keyboard.
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            _buildGlowBackground(context),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: _buildAnimatedForm(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The decorative glow: a hard circle, then a full-screen backdrop blur that
  /// diffuses it into a soft halo behind the login form.
  Widget _buildGlowBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          top: _glowTop,
          // Horizontally centered.
          left: MediaQuery.of(context).size.width / 2 - _glowDiameter / 2,
          child: Container(
            width: _glowDiameter,
            height: _glowDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withAlpha(_glowAlpha),
            ),
          ),
        ),
        // Blurs everything painted above (i.e. the circle) into a soft glow.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _glowBlurSigma, sigmaY: _glowBlurSigma),
            child: const SizedBox(),
          ),
        ),
      ],
    );
  }

  /// Fades + rises the whole form into view on first build.
  Widget _buildAnimatedForm(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            // Slide up 20px as it fades in (0px once fully visible).
            offset: Offset(0, 20 * (1 - opacity)),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBranding(context),
          const SizedBox(height: 60),
          _buildEmailField(),
          const SizedBox(height: 24),
          _buildPasswordField(context),
          const SizedBox(height: 16),
          _buildSubmitButton(context),
          const SizedBox(height: 40),
          _buildTermsNotice(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Logo + wordmark.
  Widget _buildBranding(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Image.asset(_logoAsset, width: 120, height: 120),
        const SizedBox(height: 24),
        Text(
          'FOCUSMAXXER',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  /// Username / email field.
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
      enabled: !_isLoading,
      decoration: const InputDecoration(
        labelText: 'Username or Email',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
    );
  }

  /// Password field with a show/hide toggle; submitting it triggers login.
  Widget _buildPasswordField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
    );
  }

  /// Submit button; shows a spinner in place of the label while loading.
  Widget _buildSubmitButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Text('LOGIN'),
      ),
    );
  }

  /// Terms-of-service / privacy disclaimer under the button.
  Widget _buildTermsNotice(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'By signing in, you agree to Focusmaxxer\'s Terms of Service and Privacy Policy.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
        height: 1.5,
      ),
    );
  }
}
