import 'package:flutter/material.dart';
import 'package:focusmaxxer/screens/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscurePassword = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LOGO E TITOLO
                // Nota: Sostituisci questo blocco con Image.asset('assets/logo.png')
                // quando avrai importato l'immagine nel progetto.
                const Icon(
                  Icons.show_chart_rounded, // Icona temporanea simile al battito/freccia
                  size: 80,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'FOCUSMAXXER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A NEUROERGONOMIC APPROACH TO COGNITIVE READINESS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),

                // 2. CAMPO EMAIL / USERNAME
                TextFormField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email or Username',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.cyanAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.cyanAccent, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. CAMPO PASSWORD
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.cyanAccent),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.cyanAccent, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 4. BOTTONE DI LOGIN PRINCIPALE (Con Gradiente)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.cyanAccent, Colors.orangeAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(25.0), // Bordi molto arrotondati
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (emailController.text == 'admin' && passwordController.text == '123') {
                    ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Accesso consentito! Benvenuto in FocusMaxxer.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyHomePage(title:'home')));
                        }else{
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Accesso negato! Credenziali errate.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    child: const Text(
                      'LOG IN',
                      style: TextStyle(
                        color: Colors.black, // Testo scuro per contrastare il gradiente chiaro
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. PASSWORD DIMENTICATA
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                
                // DIVIDER
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 24),

              
                // 7. REGISTRAZIONE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'New to FocusMaxxer? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      
                      onTap: () {
                        // TODO: Navigare alla pagina di registrazione
                      },
                      child: const Text(
                        'Register Here',
                        style: TextStyle(
                          color: Colors.cyanAccent,
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
    );
  }
}