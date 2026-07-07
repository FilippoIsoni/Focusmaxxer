import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_baseline.dart';

/// Thrown when the backend rejects the refresh token (HTTP 401/403), i.e. the
/// session is genuinely gone.
///
/// Lets the boot sequence route the user to the login screen instead of showing
/// a retryable "network error" that can never succeed. A transient connectivity
/// failure throws a plain [Exception] instead, so the two are never confused.
class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

/// Outcome of a token exchange (login or refresh).
///
/// Lets callers tell a real auth rejection apart from a transient network
/// problem or a server-side error, instead of overloading raw HTTP status codes
/// with magic sentinels.
enum AuthOutcome {
  /// Tokens obtained and stored successfully.
  success,

  /// The server rejected the credentials or the refresh token (HTTP 401/403).
  invalidCredentials,

  /// Connectivity or timeout failure — retryable, must NOT trigger a logout.
  networkError,

  /// Any other non-2xx response, or a 200 carrying an unusable body.
  serverError,
}

/// Talks to the IMPACT sleep backend: JWT auth (login/refresh), an authenticated
/// GET wrapper, and the morning sleep-baseline fetch used at boot.
///
/// Layer: service. This is the *only* network source in the app (HR/steps are
/// simulated locally). Tokens live in SharedPreferences; this class never logs
/// their values — only error messages.
class ImpactApiService {
  /// Optional callback invoked when the session has definitively expired, so the
  /// app can force a logout / route to login.
  Function()? onSessionExpired;

  // --- Configuration ---

  /// Timeout applied to every network call: prevents the boot sequence from
  /// hanging indefinitely if the backend never responds. On timeout a
  /// TimeoutException is thrown, already handled as an error by bootloader_screen.
  static const Duration _networkTimeout = Duration(seconds: 15);

  static const String baseUrl = 'https://impact.dei.unipd.it/bwthw/';
  static const String tokenEndpoint = 'gate/v1/token/';
  static const String refreshEndpoint = 'gate/v1/refresh/';

  /// Fixed study patient assigned for this course project; sleep data is always
  /// requested for this account.
  static const String _patientUsername = 'Jpefaq6m58';

  // --- Public API ---

  /// Fetches the sleep record and builds the [DailyBaseline] the SAFTE engine
  /// needs at boot.
  ///
  /// The record is requested for two days ago (the backend's data lag for this
  /// project). Any anomaly — non-200, malformed JSON, unexpected shape — falls
  /// back to [_getMockBaseline] so the app still boots without live sleep data.
  Future<DailyBaseline> fetchMorningBaseline() async {
    // Backend serves data with a two-day lag, so ask for two days ago.
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final String dateString = '${twoDaysAgo.year}-'
        '${twoDaysAgo.month.toString().padLeft(2, '0')}-'
        '${twoDaysAgo.day.toString().padLeft(2, '0')}';

    final endpoint = 'data/v1/sleep/patients/$_patientUsername/day/$dateString/';
    final response = await requestProtectedGet(endpoint);

    if (response.statusCode != 200) {
      throw Exception('Sleep data fetch failed (HTTP ${response.statusCode})');
    }

    // Defensive parsing — expected shape:
    //   { "status": "success", "data": { "date": "...", "data": [...] } }
    // Any deviation falls back to the mock rather than throwing.
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
        // Prefer the main nightly sleep; otherwise take the first record.
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

  /// Authenticated GET that transparently handles token expiry.
  ///
  /// It refreshes both **preemptively** (when the local token is missing/expired)
  /// and **reactively** (when the server still answers 401), retrying the call
  /// once after a successful refresh.
  Future<http.Response> requestProtectedGet(String endpoint) async {
    final sp = await SharedPreferences.getInstance();
    String? accessToken = sp.getString('access');

    // 1. Preemptive: refresh now if the token is missing or locally expired.
    if (accessToken == null || JwtDecoder.isExpired(accessToken)) {
      final outcome = await refreshTokens();
      if (outcome == AuthOutcome.success) {
        accessToken = sp.getString('access');
      } else {
        _handleRefreshFailure(outcome);
      }
    }

    final url = Uri.parse(ImpactApiService.baseUrl + endpoint);

    // Attempt with the (locally) valid access token.
    var response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(_networkTimeout);

    // 2. Reactive: the server may still reject with 401 (token revoked
    // server-side, or expired in the moment before the call). Refresh + retry once.
    if (response.statusCode == 401) {
      final outcome = await refreshTokens();
      if (outcome == AuthOutcome.success) {
        accessToken = sp.getString('access');
        response = await http.get(
          url,
          headers: {'Authorization': 'Bearer $accessToken'},
        ).timeout(_networkTimeout);
      } else {
        _handleRefreshFailure(outcome);
      }
    }

    return response;
  }

  /// Exchanges username/password for JWT tokens and stores them.
  Future<AuthOutcome> getAndStoreTokens(String username, String password) async {
    final url = ImpactApiService.baseUrl + ImpactApiService.tokenEndpoint;
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'username': username, 'password': password},
      ).timeout(_networkTimeout);
      return _outcomeFromResponse(response);
    } catch (e) {
      debugPrint('getAndStoreTokens failed: $e');
      return AuthOutcome.networkError;
    }
  }

  /// Refreshes the JWT tokens stored in SharedPreferences.
  Future<AuthOutcome> refreshTokens() async {
    final url = ImpactApiService.baseUrl + ImpactApiService.refreshEndpoint;
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');

    // No refresh token means the session is effectively gone: treat it as an
    // auth rejection so the caller logs out rather than retrying forever.
    if (refresh == null) return AuthOutcome.invalidCredentials;

    try {
      final response = await http
          .post(Uri.parse(url), body: {'refresh': refresh})
          .timeout(_networkTimeout);
      return _outcomeFromResponse(response);
    } catch (e) {
      debugPrint('refreshTokens failed: $e');
      return AuthOutcome.networkError;
    }
  }

  // --- Private helpers ---

  /// Synthetic baseline used when live sleep data is unavailable, so the engine
  /// always has something plausible to start from (a good 4-hour-ago night).
  DailyBaseline _getMockBaseline() {
    return DailyBaseline.fromJson({
      'efficiency': 96,
      'startTime':
          DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      'endTime': DateTime.now().toIso8601String(),
      'mainSleep': true,
    });
  }

  /// Maps a completed HTTP response to an [AuthOutcome], storing tokens on a
  /// valid 200. A 200 with an unusable body is treated as a server error.
  Future<AuthOutcome> _outcomeFromResponse(http.Response response) async {
    if (response.statusCode == 200) {
      return await _storeTokensFromBody(response.body)
          ? AuthOutcome.success
          : AuthOutcome.serverError;
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return AuthOutcome.invalidCredentials;
    }
    return AuthOutcome.serverError;
  }

  /// Parses a token response body and persists access/refresh only if both are
  /// valid non-empty strings. Returns false on a malformed payload so the caller
  /// never stores a null/garbage token.
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
      // Logs the failure only — never the token contents.
      debugPrint('Token store failed: $e');
      return false;
    }
  }

  /// Reacts to a failed token refresh. Forces a logout only on a genuine auth
  /// rejection; a network/timeout/server failure is surfaced as a retryable
  /// error WITHOUT logging the user out, so a transient blip does not destroy
  /// the session.
  Never _handleRefreshFailure(AuthOutcome outcome) {
    if (outcome == AuthOutcome.invalidCredentials) {
      onSessionExpired?.call();
      throw const SessionExpiredException();
    }
    throw Exception('NetworkError');
  }
}
