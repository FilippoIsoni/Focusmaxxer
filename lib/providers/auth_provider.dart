import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Aggiunto per la memoria

enum AuthStatus { unknown, firstTime, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  // variabili per nome, cognome e soprannome
  String _name = '';
  String _surname = '';
  String _nickname = '';

  AuthStatus get status => _status;
  String get name => _name;
  String get surname => _surname;
  String get nickname => _nickname;

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
    _name = prefs.getString('profile_name') ?? '';
    _surname = prefs.getString('profile_surname') ?? '';
    _nickname = prefs.getString('profile_nickname') ?? 'Student';

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

  // CANCELLA il login dalla memoria
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Dimentica l'utente
    
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // --- NUOVI METODI PER IL PROFILO ---

  //Salva i dati anagrafici inseriti dall'utente
  Future<void> updateProfile(String newName, String newSurname, String newNickname) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('profile_name', newName);
    await prefs.setString('profile_surname', newSurname);
    await prefs.setString('profile_nickname', newNickname);

    // Aggiorniamo la RAM e avvisiamo la UI
    _name = newName;
    _surname = newSurname;
    _nickname = newNickname;
    
    notifyListeners();
  }

  //Cancella solo l'identità (usato dal tasto rosso della ProfilePage)
  Future<void> clearProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('profile_name');
    await prefs.remove('profile_surname');
    await prefs.remove('profile_nickname');

    // Resettiamo la RAM ai valori di default
    _name = '';
    _surname = '';
    _nickname = 'Student';
    
    notifyListeners();
  }
}