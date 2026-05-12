import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_baseline.dart';

class ImpactApiService {
  Function()? onSessionExpired;

  Future<DailyBaseline> fetchMorningBaseline() async {
    // Simula ritardo di rete
    await Future.delayed(const Duration(milliseconds: 500));

    final mockJson = {
      "dateOfSleep": DateTime.now().toIso8601String().substring(0, 10),
      "startTime": DateTime.now()
          .subtract(const Duration(hours: 4, minutes: 30))
          .toIso8601String(),
      "endTime": DateTime.now()
          .subtract(const Duration(minutes: 10))
          .toIso8601String(),
      "duration": 2.832E+7,
      "minutesToFallAsleep": 0,
      "minutesAsleep": 429, // Real data key
      "minutesAwake": 43,
      "minutesAfterWakeup": 3,
      "timeInBed": 472,
      "efficiency": 96, // Real data key
      "logType": "auto_detected",
      "mainSleep": true,
    };

    return DailyBaseline.fromJson(mockJson);
  }

  static String baseUrl = 'https://impact.dei.unipd.it/bwthw/';
  static String pingEndpoint = 'gate/v1/ping/';
  static String tokenEndpoint = 'gate/v1/token/';
  static String refreshEndpoint = 'gate/v1/refresh/';

  //This method allows to refresh the stored JWT in SharedPreferences
  Future<int> refreshTokens() async {
    //Create the request
    final url = ImpactApiService.baseUrl + ImpactApiService.refreshEndpoint;
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');
    if (refresh != null) {
      final body = {'refresh': refresh};

      //Get the response
      print('Calling: $url');
      final response = await http.post(Uri.parse(url), body: body);

      //If the response is OK, set the tokens in SharedPreferences to the new values
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final sp = await SharedPreferences.getInstance();
        await sp.setString('access', decodedResponse['access']);
        await sp.setString('refresh', decodedResponse['refresh']);
      } //if

      //Just return the status code
      return response.statusCode;
    }
    return 401;
  } //_refreshTokens

  Future<int> getAndStoreTokens(String username, String password) async {
    //Create the request
    final url = ImpactApiService.baseUrl + ImpactApiService.tokenEndpoint;
    final body = {'username': username, 'password': password};

    //Get the response
    print('Calling: $url');
    final response = await http.post(Uri.parse(url), body: body);

    //If response is OK, decode it and store the tokens. Otherwise do nothing.
    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('access', decodedResponse['access']);
      await sp.setString('refresh', decodedResponse['refresh']);
    } //if

    //Just return the status code
    return response.statusCode;
  } //_getAndStoreTokens

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
