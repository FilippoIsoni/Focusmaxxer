import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Aggiunto per la memoria

enum AuthStatus { unknown, firstTime, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  // variabili per nome, cognome e soprannome
  String name = '';
  String surname = '';
  String nickname = '';

  AuthProvider() {
    _checkInitialState();
  }

  // 1. Ora LEGGE la memoria vera del telefono all'avvio
  Future<void> _checkInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    // Controlliamo i dati salvati. Se non ci sono, usiamo i default (true per il primo avvio)
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    // Leggiamo anche i dati del profilo, se esistono
    name = prefs.getString('profile_name') ?? '';
    surname = prefs.getString('profile_surname') ?? '';
    nickname = prefs.getString('profile_nickname') ?? 'Student';
    // Decidiamo lo stato iniziale basandoci sulla memoria
    if (isFirstTime) {
      status = AuthStatus.firstTime;
    } else if (isLoggedIn) {
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // 2. SCRIVE in memoria che il carosello è stato completato
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false); 
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // 3. SCRIVE in memoria che l'utente ha fatto il login
  Future<void> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (username == 'admin' && password == '123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);  
      status = AuthStatus.authenticated;
      notifyListeners();
    } else {
      throw Exception('Credenziali errate');
    }
  }

  // CANCELLA il login dalla memoria
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Dimentica l'utente
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // METODI PER IL PROFILO ---

  //Salva i dati anagrafici inseriti dall'utente
  Future<void> updateProfile(String newName, String newSurname, String newNickname) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('profile_name', newName);
    await prefs.setString('profile_surname', newSurname);
    await prefs.setString('profile_nickname', newNickname);

    // Aggiorniamo la RAM e avvisiamo la UI
    name = newName;
    surname = newSurname;
    nickname = newNickname;
    
    notifyListeners();
  }

  //Cancella solo l'identità (usato dal tasto rosso della ProfilePage)
  Future<void> clearProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('profile_name');
    await prefs.remove('profile_surname');
    await prefs.remove('profile_nickname');

    // Resettiamo la RAM ai valori di default
    name = '';
    surname = '';
    nickname = 'Student';
    
    notifyListeners();
  }
}
