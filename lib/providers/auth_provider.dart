import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/impact_api_service.dart';

/// Coarse authentication/onboarding phase the app UI routes on.
enum AuthStatus { unknown, firstTime, unauthenticated, authenticated }

/// Tracks whether the user is onboarded, logged in, and their profile identity.
///
/// Layer: provider (session/identity). It is the single source of truth for
/// [AuthStatus] and the cached profile fields, backed by [SharedPreferences] for
/// the flags/profile and delegating actual token exchange to [ImpactApiService].
/// Note: only the JWTs (owned by the API service) authenticate the user; the
/// `isLoggedIn` flag here is a convenience cache validated against the refresh
/// token on startup.
class AuthProvider extends ChangeNotifier {
  // ==========================================
  // PERSISTENCE KEYS
  // ==========================================
  // Centralized so the exact string is written/read from one place only.
  static const String _keyIsFirstTime = 'isFirstTime';
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyRefreshToken = 'refresh';
  static const String _keyProfileName = 'profile_name';
  static const String _keyProfileSurname = 'profile_surname';
  static const String _keyProfileNickname = 'profile_nickname';

  /// Default nickname shown before the user sets one (and after clearing it).
  static const String _defaultNickname = 'Student';

  // ==========================================
  // STATE
  // ==========================================
  AuthStatus status = AuthStatus.unknown;

  // Cached profile identity (mirrored in prefs).
  String name = '';
  String surname = '';
  String nickname = '';

  final SharedPreferences prefs;

  AuthProvider(this.prefs) {
    _checkInitialStateSync();
  }

  // ==========================================
  // INITIALIZATION
  // ==========================================

  /// Reads persisted flags/profile synchronously at construction to decide the
  /// initial [status] before the first frame (no async gap on launch).
  void _checkInitialStateSync() {
    // Default to first-time on a fresh install (no keys stored yet).
    bool isFirstTime = prefs.getBool(_keyIsFirstTime) ?? true;
    bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    // Guard: a stored login is only trustworthy while the refresh token is
    // still valid. If it is missing or expired, force the user back to login so
    // we never present an authenticated UI on top of a dead session.
    if (isLoggedIn) {
      final String? refreshToken = prefs.getString(_keyRefreshToken);
      if (refreshToken == null || JwtDecoder.isExpired(refreshToken)) {
        isLoggedIn = false;
        prefs.setBool(_keyIsLoggedIn, false);
      }
    }

    // Restore the cached profile, falling back to the default nickname.
    name = prefs.getString(_keyProfileName) ?? '';
    surname = prefs.getString(_keyProfileSurname) ?? '';
    nickname = prefs.getString(_keyProfileNickname) ?? _defaultNickname;

    // Resolve the initial phase: onboarding takes precedence over login state.
    if (isFirstTime) {
      status = AuthStatus.firstTime;
    } else if (isLoggedIn) {
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ==========================================
  // AUTH TRANSITIONS
  // ==========================================

  /// Marks onboarding as done and moves the user to the login screen.
  Future<void> completeOnboarding() async {
    await prefs.setBool(_keyIsFirstTime, false);
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Persists the logged-in flag after a successful token exchange.
  ///
  /// The [api] instance is passed in by the caller (the DI-registered singleton)
  /// so we reuse the same service — with its onSessionExpired callback already
  /// wired — instead of spawning a second instance. Returns the [AuthOutcome] so
  /// the UI can show a message that matches the real failure mode (wrong
  /// credentials vs. no network vs. server error).
  Future<AuthOutcome> login(
    ImpactApiService api,
    String username,
    String password,
  ) async {
    final outcome = await api.getAndStoreTokens(username, password);

    // Only flip to authenticated when the tokens were actually stored.
    if (outcome == AuthOutcome.success) {
      await prefs.setBool(_keyIsLoggedIn, true);
      status = AuthStatus.authenticated;
      notifyListeners();
    }
    return outcome;
  }

  /// Clears the logged-in flag and returns the user to the unauthenticated UI.
  Future<void> logout() async {
    await prefs.setBool(_keyIsLoggedIn, false);
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ==========================================
  // PROFILE
  // ==========================================

  /// Saves the user's personal data to disk, then updates the in-memory cache
  /// and notifies the UI.
  Future<void> updateProfile(
    String newName,
    String newSurname,
    String newNickname,
  ) async {
    await prefs.setString(_keyProfileName, newName);
    await prefs.setString(_keyProfileSurname, newSurname);
    await prefs.setString(_keyProfileNickname, newNickname);

    name = newName;
    surname = newSurname;
    nickname = newNickname;

    notifyListeners();
  }

  /// Clears only the profile identity (used by the ProfilePage reset button),
  /// resetting the in-memory cache to defaults. Does not affect login state.
  Future<void> clearProfileData() async {
    await prefs.remove(_keyProfileName);
    await prefs.remove(_keyProfileSurname);
    await prefs.remove(_keyProfileNickname);

    name = '';
    surname = '';
    nickname = _defaultNickname;

    notifyListeners();
  }
}
