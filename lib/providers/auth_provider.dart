import 'package:flutter/material.dart';

enum AuthStatus { unknown, firstTime, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;

  AuthStatus get status => _status;

  AuthProvider() {
    _checkInitialState();
  }

  // Simula il controllo di SharedPreferences/SecureStorage all'avvio
  Future<void> _checkInitialState() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // Per l'MVP, forziamo il primo avvio per testare l'onboarding
    _status = AuthStatus.firstTime;
    notifyListeners();
  }

  void completeOnboarding() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (username == 'admin' && password == '123') {
      _status = AuthStatus.authenticated;
      notifyListeners();
    } else {
      throw Exception('Credenziali errate');
    }
  }

  void logout() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
