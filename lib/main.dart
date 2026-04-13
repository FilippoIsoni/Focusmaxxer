import 'package:flutter/material.dart';
import 'package:focusmaxxer/screens/loginpage.dart';
import 'package:focusmaxxer/screens/homepage.dart';

import 'screens/OnBoardingPage.dart';

void main() {
  runApp(const FocusMaxxerApp());
}

class FocusMaxxerApp extends StatelessWidget {
  const FocusMaxxerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusMaxxer',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B132B), // Sfondo Deep Blue
        colorScheme: ColorScheme.dark(
          primary: Colors.cyanAccent,
          surface: const Color(0xFF111C3A), // Colore dei bottoni secondari
        ),
        fontFamily: 'Roboto', // Sostituibile con Poppins o Montserrat
      ),
      home: const OnboardingPage(),
    );
  }
}
