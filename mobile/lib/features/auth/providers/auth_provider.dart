import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';

class UserSession {
  final String userId;
  final String displayName;
  final String email;
  final String role; // 'ARTIST' | 'CLIENT'
  final String token;

  const UserSession({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.token,
  });

  bool get isArtist => role.toUpperCase() == 'ARTIST';
  bool get isClient => role.toUpperCase() == 'CLIENT';

  UserSession copyWith({
    String? displayName,
    String? email,
    String? role,
  }) {
    return UserSession(
      userId: userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token,
    );
  }
}

class AuthState {
  final bool isLoading;
  final UserSession? user;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    UserSession? user,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kTokenKey = 'inksight_jwt_token';
  static const _kUserEmailKey = 'inksight_user_email';
  static const _kUserNameKey = 'inksight_user_name';
  static const _kUserRoleKey = 'inksight_user_role';
  static const _kUserIdKey = 'inksight_user_id';

  AuthNotifier(this._apiClient) : super(const AuthState()) {
    checkSavedSession();
  }

  /// Restores session on app startup
  Future<void> checkSavedSession() async {
    try {
      final token = await _storage.read(key: _kTokenKey);
      if (token != null && token.isNotEmpty) {
        final email = await _storage.read(key: _kUserEmailKey) ?? 'usuario@inksight.app';
        final name = await _storage.read(key: _kUserNameKey) ?? 'Usuario InkSight';
        final role = await _storage.read(key: _kUserRoleKey) ?? 'CLIENT';
        final userId = await _storage.read(key: _kUserIdKey) ?? 'user_local';

        _apiClient.setAccessToken(token);

        state = state.copyWith(
          user: UserSession(
            userId: userId,
            displayName: name,
            email: email,
            role: role,
            token: token,
          ),
          isInitialized: true,
        );
        return;
      }
    } catch (e) {
      debugPrint('Error restoring saved session: $e');
    }
    state = state.copyWith(isInitialized: true);
  }

  /// Authenticate with email/username and password (must be 6-15 chars)
  Future<bool> login({required String email, required String password}) async {
    final validationError = validatePassword(password);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.login(
        email: email.trim(),
        password: password,
      );

      final user = UserSession(
        userId: response.userId,
        displayName: response.displayName ?? email.split('@').first,
        email: response.email ?? email,
        role: response.role,
        token: response.accessToken,
      );

      await _persistSession(user);
      _apiClient.setAccessToken(response.accessToken);

      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Credenciales inválidas o error de conexión.',
      );
      return false;
    }
  }

  /// Register new user account with role selection
  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
    required String role,
  }) async {
    final validationError = validatePassword(password);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    if (displayName.trim().length < 2) {
      state = state.copyWith(errorMessage: 'El nombre debe tener al menos 2 caracteres.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.register(
        displayName: displayName.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        role: role.toUpperCase(),
      );

      final user = UserSession(
        userId: response.userId,
        displayName: response.displayName ?? displayName,
        email: response.email ?? email,
        role: response.role,
        token: response.accessToken,
      );

      await _persistSession(user);
      _apiClient.setAccessToken(response.accessToken);

      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'El correo ya está registrado o datos inválidos.',
      );
      return false;
    }
  }

  /// Strict validation rule: Minimum 6 and maximum 15 characters
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres.';
    }
    if (password.length > 15) {
      return 'La contraseña debe tener máximo 15 caracteres.';
    }
    return null;
  }

  /// Logout and clear storage
  Future<void> logout() async {
    try {
      await _storage.delete(key: _kTokenKey);
      await _storage.delete(key: _kUserEmailKey);
      await _storage.delete(key: _kUserNameKey);
      await _storage.delete(key: _kUserRoleKey);
      await _storage.delete(key: _kUserIdKey);
    } catch (_) {}

    _apiClient.clearAuth();
    state = state.copyWith(clearUser: true, errorMessage: null);
  }

  Future<void> _persistSession(UserSession user) async {
    try {
      await _storage.write(key: _kTokenKey, value: user.token);
      await _storage.write(key: _kUserEmailKey, value: user.email);
      await _storage.write(key: _kUserNameKey, value: user.displayName);
      await _storage.write(key: _kUserRoleKey, value: user.role);
      await _storage.write(key: _kUserIdKey, value: user.userId);
    } catch (_) {}
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  // Uses Android emulator host or localhost depending on platform
  const baseUrl = 'http://localhost:3000';
  return ApiClient(baseUrl: baseUrl);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});
