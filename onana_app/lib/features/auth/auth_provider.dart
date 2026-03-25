import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/router/app_router.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.userId,
    this.fullName,
    this.email,
    this.role,
  });

  final AuthStatus status;
  final String? userId;
  final String? fullName;
  final String? email;
  final String? role;

  static const AuthState unknown =
      AuthState(status: AuthStatus.unknown);
  static const AuthState unauthenticated =
      AuthState(status: AuthStatus.unauthenticated);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Used by GoRouter as refreshListenable.
final routerRefreshNotifier = ValueNotifier<int>(0);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return AuthState.unknown;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      _setUnauthenticated();
      return;
    }
    try {
      final response =
          await ApiClient.instance.get<Map<String, dynamic>>('/auth/me');
      _setAuthenticated(response.data!);
    } catch (_) {
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      _setUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    final loginResp = await ApiClient.instance
        .post<Map<String, dynamic>>('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final tokens = loginResp.data!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'access_token', tokens['access_token'] as String);
    await prefs.setString(
        'refresh_token', tokens['refresh_token'] as String);

    final meResp = await ApiClient.instance
        .get<Map<String, dynamic>>('/auth/me');
    _setAuthenticated(meResp.data!);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _setUnauthenticated();
  }

  void _setAuthenticated(Map<String, dynamic> me) {
    state = AuthState(
      status: AuthStatus.authenticated,
      userId: me['id'] as String?,
      fullName: me['full_name'] as String?,
      email: me['email'] as String?,
      role: me['role'] as String?,
    );
    updateRouterAuthStatus(AuthStatus.authenticated);
    routerRefreshNotifier.value++;
  }

  void _setUnauthenticated() {
    state = AuthState.unauthenticated;
    updateRouterAuthStatus(AuthStatus.unauthenticated);
    routerRefreshNotifier.value++;
  }
}
