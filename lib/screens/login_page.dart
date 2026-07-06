import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/impact_api_service.dart';
import '../utils/dashboard_helpers.dart'; // Router
import 'bootloader_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await context.read<AuthProvider>().login(
        context.read<ImpactApiService>(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Nuova Transizione: Immersione nel Bootloader (il sistema "risucchia" l'utente)
      Navigator.of(
        context,
      ).pushReplacement(ImmersiveRoute(page: const BootloaderScreen()));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final colorScheme = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.onError),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Invalid credentials. Please try again.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // DEEP DARK GLOW BACKGROUND
            Positioned(
              top: 100,
              left: MediaQuery.of(context).size.width / 2 - 150,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withAlpha(15), // Uniformato
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - opacity)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // BRAND ICON
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/focusmaxxer_logo_v3.png',
                            width: 120,
                            height: 120,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'FOCUSMAXXER',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 60),

                        TextFormField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Username or Email',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
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
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        
                        SizedBox(
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
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'By signing in, you agree to Focusmaxxer\'s Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withAlpha(150),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
