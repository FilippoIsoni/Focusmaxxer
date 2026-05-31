import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_baseline.dart';

class ImpactApiService {
  Function()? onSessionExpired;

  /// Recupera i dati del sonno di 2 giorni fa e costruisce l'oggetto DailyBaseline.
  Future<DailyBaseline> fetchMorningBaseline() async {
    const patientUsername = 'Jpefaq6m58'; 
    
    // 1. Calcoliamo la data (2 giorni fa, come richiesto dal prof)
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final String dateString = "${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}";
    
    // 2. Costruiamo l'endpoint ed eseguiamo la richiesta
    final endpoint = 'data/v1/sleep/patients/$patientUsername/day/$dateString/';
    final response = await requestProtectedGet(endpoint);

    if (response.statusCode != 200) {
      throw Exception('Errore nel recupero dati (HTTP ${response.statusCode})');
    }

    // 3. Parsing corretto basato sulla struttura reale dell'API
// Struttura reale: { "status": "success", "data": { "date": "...", "data": { ... } } }
    final decodedResponse = jsonDecode(response.body);

    final Map<String, dynamic>? outerData = decodedResponse['data'] as Map<String, dynamic>?;

// I dati possono essere un oggetto singolo o una lista
    final dynamic rawData = outerData?['data'];
    Map<String, dynamic>? sessionData;

    if (rawData is List && rawData.isNotEmpty) {
      // Se è una lista, cerchiamo mainSleep == true, altrimenti prendiamo il primo
      sessionData = rawData.firstWhere(
        (s) => s is Map && s['mainSleep'] == true,
        orElse: () => rawData.first,
      ) as Map<String, dynamic>?;
    } else if (rawData is Map) {
      // Se è già un oggetto singolo, lo prendiamo direttamente
      sessionData = rawData as Map<String, dynamic>;
    }
    print('📅 Data richiesta: $dateString');
    print('📦 Outer data: $outerData');
    print('😴 Session data: $sessionData');
    print('⚡ Usando mock: ${sessionData == null}');


    return sessionData != null
        ? DailyBaseline.fromJson(sessionData)
        : _getMockBaseline();
  }

  DailyBaseline _getMockBaseline() {
    return DailyBaseline.fromJson({
      "efficiency": 96,
      "startTime": DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      "endTime": DateTime.now().toIso8601String(),
      "mainSleep": true,
    });
  }

  static String baseUrl = 'https://impact.dei.unipd.it/bwthw/';
  static String pingEndpoint = 'gate/v1/ping/';
  static String tokenEndpoint = 'gate/v1/token/';
  static String refreshEndpoint = 'gate/v1/refresh/';

  /// Esegue il refresh dei token JWT memorizzati in SharedPreferences.
  Future<int> refreshTokens() async {
    final url = ImpactApiService.baseUrl + ImpactApiService.refreshEndpoint;
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');
    
    if (refresh == null) return 401;

    final response = await http.post(Uri.parse(url), body: {'refresh': refresh});

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      await sp.setString('access', decodedResponse['access']);
      await sp.setString('refresh', decodedResponse['refresh']);
    }

    return response.statusCode;
  }

  /// Ottiene ed archivia i token JWT a partire da username e password.
  Future<int> getAndStoreTokens(String username, String password) async {
    final url = ImpactApiService.baseUrl + ImpactApiService.tokenEndpoint;
    
    final response = await http.post(Uri.parse(url), body: {
      'username': username,
      'password': password,
    });

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('access', decodedResponse['access']);
      await sp.setString('refresh', decodedResponse['refresh']);
    }

    return response.statusCode;
  }

  /// Wrapper per chiamate autenticate (GET) che gestisce in automatico
  /// l'errore 401 e il refresh dei token (sia in modo preventivo che reattivo).
  Future<http.Response> requestProtectedGet(String endpoint) async {
    final sp = await SharedPreferences.getInstance();
    String? accessToken = sp.getString('access');

    // 1. Controllo preventivo: se non c'è token o è scaduto localmente, facciamo subito il refresh
    if (accessToken == null || JwtDecoder.isExpired(accessToken)) {
      final refreshStatus = await refreshTokens();
      if (refreshStatus == 200) {
        accessToken = sp.getString('access');
      } else {
        // Se il refresh fallisce (es. scaduto anche quello), forziamo il logout
        if (onSessionExpired != null) {
          onSessionExpired!();
        }
        throw Exception('SessionExpired');
      }
    }

    final url = Uri.parse(ImpactApiService.baseUrl + endpoint);
    
    // Tentativo con l'access token valido (secondo la scadenza locale)
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    // 2. Controllo reattivo: se il server risponde 401 per altri motivi 
    // (es. token revocato dal server o scaduto nel millisecondo prima della richiesta)
    if (response.statusCode == 401) {
      final refreshStatus = await refreshTokens();
      
      if (refreshStatus == 200) {
        // Refresh andato a buon fine, ritentiamo
        accessToken = sp.getString('access');
        response = await http.get(url, headers: {
          'Authorization': 'Bearer $accessToken',
        });
      } else {
        // Definitivamente scaduto
        if (onSessionExpired != null) {
          onSessionExpired!();
        }
        throw Exception('SessionExpired');
      }
    }

    return response;
  }
}
