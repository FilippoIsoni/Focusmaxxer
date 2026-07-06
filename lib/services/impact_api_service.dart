import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_baseline.dart';

class ImpactApiService {
  Function()? onSessionExpired;

  /// Timeout applied to every network call: prevents the boot sequence from
  /// hanging indefinitely if the backend never responds. On timeout a
  /// TimeoutException is thrown, already handled as an error by bootloader_screen.
  static const Duration _networkTimeout = Duration(seconds: 15);

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

    // 3. Defensive parsing — real structure:
    //    { "status": "success", "data": { "date": "...", "data": [...] } }
    //    Any anomaly (malformed JSON, unexpected shape, missing data) falls
    //    back to the mock instead of throwing an unhandled exception.
    try {
      final dynamic decodedResponse = jsonDecode(response.body);
      final dynamic topLevel =
          decodedResponse is Map ? decodedResponse['data'] : null;
      if (topLevel is! Map) {
        return _getMockBaseline();
      }

      final dynamic rawData = topLevel['data'];
      Map<String, dynamic>? sessionData;

      if (rawData is List && rawData.isNotEmpty) {
        final match = rawData.firstWhere(
          (s) => s is Map && s['mainSleep'] == true,
          orElse: () => rawData.first,
        );
        if (match is Map) sessionData = Map<String, dynamic>.from(match);
      } else if (rawData is Map) {
        sessionData = Map<String, dynamic>.from(rawData);
      }

      if (sessionData == null) {
        return _getMockBaseline();
      }

      return DailyBaseline.fromJson(sessionData);
    } catch (e) {
      return _getMockBaseline();
    }
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

  // Non-HTTP status codes used internally to distinguish failure modes so
  // callers can tell a transient network problem apart from a real auth
  // rejection (see requestProtectedGet).
  static const int _networkErrorStatus = 0;
  static const int _malformedBodyStatus = 599;

  /// Parses a token response body and persists access/refresh only if both are
  /// valid non-empty strings. Returns false on a malformed payload so the
  /// caller never stores a null/garbage token.
  Future<bool> _storeTokensFromBody(String body) async {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return false;
      final access = decoded['access'];
      final refresh = decoded['refresh'];
      if (access is! String ||
          access.isEmpty ||
          refresh is! String ||
          refresh.isEmpty) {
        return false;
      }
      final sp = await SharedPreferences.getInstance();
      await sp.setString('access', access);
      await sp.setString('refresh', refresh);
      return true;
    } catch (e) {
      debugPrint('Token store failed: $e');
      return false;
    }
  }

  /// Refreshes the JWT tokens stored in SharedPreferences.
  /// Returns the HTTP status on completion, [_networkErrorStatus] on a
  /// network/timeout failure, or [_malformedBodyStatus] if a 200 carried an
  /// unusable body.
  Future<int> refreshTokens() async {
    final url = ImpactApiService.baseUrl + ImpactApiService.refreshEndpoint;
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');

    if (refresh == null) return 401;

    try {
      final response = await http
          .post(Uri.parse(url), body: {'refresh': refresh})
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        return await _storeTokensFromBody(response.body)
            ? 200
            : _malformedBodyStatus;
      }
      return response.statusCode;
    } catch (e) {
      debugPrint('refreshTokens failed: $e');
      return _networkErrorStatus;
    }
  }

  /// Exchanges username/password for JWT tokens and stores them.
  /// Same status contract as [refreshTokens].
  Future<int> getAndStoreTokens(String username, String password) async {
    final url = ImpactApiService.baseUrl + ImpactApiService.tokenEndpoint;

    try {
      final response = await http.post(Uri.parse(url), body: {
        'username': username,
        'password': password,
      }).timeout(_networkTimeout);

      if (response.statusCode == 200) {
        return await _storeTokensFromBody(response.body)
            ? 200
            : _malformedBodyStatus;
      }
      return response.statusCode;
    } catch (e) {
      debugPrint('getAndStoreTokens failed: $e');
      return _networkErrorStatus;
    }
  }

  /// Reacts to a failed token refresh. Forces a logout only on a genuine auth
  /// rejection (401/403); a network/timeout/server failure is surfaced as a
  /// retryable error WITHOUT logging the user out, so a transient connectivity
  /// blip does not destroy the session.
  Never _handleRefreshFailure(int status) {
    if (status == 401 || status == 403) {
      onSessionExpired?.call();
      throw Exception('SessionExpired');
    }
    throw Exception('NetworkError ($status)');
  }

  /// Wrapper for authenticated GET calls that transparently handles 401s and
  /// token refresh, both preemptively (local expiry) and reactively (server 401).
  Future<http.Response> requestProtectedGet(String endpoint) async {
    final sp = await SharedPreferences.getInstance();
    String? accessToken = sp.getString('access');

    // 1. Preemptive check: if the token is missing or locally expired, refresh now.
    if (accessToken == null || JwtDecoder.isExpired(accessToken)) {
      final refreshStatus = await refreshTokens();
      if (refreshStatus == 200) {
        accessToken = sp.getString('access');
      } else {
        _handleRefreshFailure(refreshStatus);
      }
    }

    final url = Uri.parse(ImpactApiService.baseUrl + endpoint);

    // Attempt with the (locally) valid access token.
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $accessToken',
    }).timeout(_networkTimeout);

    // 2. Reactive check: the server may reject with 401 for other reasons
    // (token revoked server-side, or expired in the millisecond before the call).
    if (response.statusCode == 401) {
      final refreshStatus = await refreshTokens();

      if (refreshStatus == 200) {
        accessToken = sp.getString('access');
        response = await http.get(url, headers: {
          'Authorization': 'Bearer $accessToken',
        }).timeout(_networkTimeout);
      } else {
        _handleRefreshFailure(refreshStatus);
      }
    }

    return response;
  }
}
