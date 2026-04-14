import 'package:flutter/material.dart';
import 'homepage.dart'; // Assicurati che questo file esista

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false; // Gestisce lo stato di caricamento
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    // 1. Chiude la tastiera
    FocusScope.of(context).unfocus();

    // 2. Avvia l'animazione di caricamento sul bottone
    setState(() => _isLoading = true);

    // Simuliamo il tempo di rete / calcolo (1.5 secondi)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Se il widget è stato chiuso prima della fine dell'attesa, interrompiamo
    if (!mounted) return;

    // 3. Logica di validazione
    if (_emailController.text == 'admin' && _passwordController.text == '123') {
      // In caso di successo, naviga alla Home (il feedback positivo è intrinseco)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Dashboard'),
        ),
      );
    } else {
      // In caso di errore, fermiamo il caricamento e mostriamo l'errore
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Credenziali errate. Riprova.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // GestureDetector rileva i tap sullo sfondo vuoto per chiudere la tastiera
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              // Animazione di ingresso in dissolvenza (Fade-in)
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - opacity)), // Sale leggermente
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. HEADER (Con effetto Glow Bioluminescente)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colorScheme.primary.withAlpha(51), // 20% alpha
                            colorScheme.primary.withAlpha(0),
                          ],
                          radius: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'FOCUSMAXXER',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 60),

                    // 2. CAMPO EMAIL
                    TextFormField(
                      controller: _emailController,
                      textInputAction: TextInputAction.next, // Tasto 'Avanti'
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading, // Disabilita durante il caricamento
                      decoration: const InputDecoration(
                        labelText: 'Email o Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. CAMPO PASSWORD
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done, // Tasto 'Fine'
                      onFieldSubmitted: (_) =>
                          _handleLogin(), // Invio esegue il login
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. PASSWORD DIMENTICATA
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : () {},
                        child: Text(
                          'Password dimenticata?',
                          style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(179),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 5. BOTTONE DI LOGIN (Reattivo e con Spinner)
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        // Se sta caricando, null disabilita il bottone nativamente
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Text('ACCEDI'),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 6. REGISTRAZIONE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nuovo utente? ',
                          style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(179),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : () {},
                          child: Text(
                            'Registrati ora',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
