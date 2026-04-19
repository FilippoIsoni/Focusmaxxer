import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Aggiunto per la memoria

enum AuthStatus { unknown, firstTime, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;

  AuthStatus get status => _status;

  AuthProvider() {
    _checkInitialState();
  }

  // 1. Ora LEGGE la memoria vera del telefono all'avvio
  Future<void> _checkInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Controlliamo i dati salvati. Se non ci sono, usiamo i default (true per il primo avvio)
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Decidiamo lo stato iniziale basandoci sulla memoria
    if (isFirstTime) {
      _status = AuthStatus.firstTime;
    } else if (isLoggedIn) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  // 2. SCRIVE in memoria che il carosello è stato completato
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false); // Salva per sempre
    
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // 3. SCRIVE in memoria che l'utente ha fatto il login
  Future<void> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (username == 'admin' && password == '123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true); // Salva il login per sempre
      
      _status = AuthStatus.authenticated;
      notifyListeners();
    } else {
      throw Exception('Credenziali errate');
    }
  }

  // 4. CANCELLA il login dalla memoria
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Dimentica l'utente
    
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}