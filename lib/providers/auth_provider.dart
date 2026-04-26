import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rs2_desktop/core/api/api_client.dart';
import 'package:rs2_desktop/core/constants/app_constants.dart';
import 'package:rs2_desktop/core/errors/ui_error_mapper.dart';
import 'package:rs2_desktop/core/services/api/api_service.dart';
import 'package:rs2_desktop/core/services/api/auth_api_service.dart';
import 'package:rs2_desktop/models/auth/auth_response.dart';
import 'package:rs2_desktop/models/auth/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();
  final ApiClient _apiClient = ApiClient();
  final ApiService _legacyApiService = ApiService();

  // State
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.role == AppConstants.roleAdmin;
  bool get isWaiter => _currentUser?.role == AppConstants.roleWaiter;
  bool get isBartender => _currentUser?.role == AppConstants.roleBartender;

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'current_user';

  AuthProvider() {
    _apiClient.onUnauthorized = _handleUnauthorized;
    _legacyApiService.onUnauthorized = _handleUnauthorized;
  }

  /// Initialize - Load saved credentials
  Future<void> initialize() async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final savedUserJson = prefs.getString(_userKey);

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        _apiClient.setToken(savedToken);
        _restoreCachedUser(savedUserJson);

        await _legacyApiService.saveToken(savedToken);

        final response = await _apiService.validateToken(savedToken);

        if (response.success && response.data == true) {
          final userResponse = await _apiService.getCurrentUser();
          if (userResponse.success && userResponse.data != null) {
            _currentUser = userResponse.data;
            _isAuthenticated = true;
          } else {
            await _clearCredentials();
          }
        } else {
          final savedRefreshToken = prefs.getString(_refreshTokenKey);
          if (savedRefreshToken != null) {
            final refreshResponse = await _apiService.refreshToken(
              savedRefreshToken,
            );
            if (refreshResponse.success && refreshResponse.data != null) {
              await _handleAuthSuccess(refreshResponse.data!);
            } else {
              await _clearCredentials();
            }
          } else {
            await _clearCredentials();
          }
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      await _clearCredentials();
    } finally {
      _setLoading(false);
    }
  }

  /// Login
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        await _handleAuthSuccess(response.data!);
        return true;
      } else {
        _setError(response.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to sign in right now. Please try again.',
        ).userMessage,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phoneNumber: phoneNumber,
      );

      if (response.success && response.data != null) {
        await _handleAuthSuccess(response.data!);
        return true;
      } else {
        _setError(response.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to complete registration right now.',
        ).userMessage,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _clearCredentials();
      _setLoading(false);
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response.success) {
        return true;
      } else {
        _setError(response.error ?? 'Password change failed');
        return false;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to change password right now.',
        ).userMessage,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;

    try {
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null) {
        _currentUser = response.data;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(response.data!.toJson()));

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh user error: $e');
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.forgotPassword(email);

      if (response.success) {
        return true;
      } else {
        _setError(response.error ?? 'Password reset request failed');
        return false;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to request a password reset right now.',
        ).userMessage,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );

      if (response.success) {
        return true;
      } else {
        _setError(response.error ?? 'Password reset failed');
        return false;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to reset password right now.',
        ).userMessage,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== PRIVATE HELPERS ==========

  Future<void> _handleAuthSuccess(AuthResponse authResponse) async {
    _token = authResponse.accessToken;
    _currentUser = UserModel(
      id: authResponse.userId,
      fullName: authResponse.fullName,
      email: authResponse.email,
      role: authResponse.role,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _isAuthenticated = true;

    _apiClient.setToken(_token);

    await _legacyApiService.saveToken(_token!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    if (authResponse.refreshToken != null) {
      await prefs.setString(_refreshTokenKey, authResponse.refreshToken!);
    }
    await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

    notifyListeners();
  }

  Future<void> _clearCredentials() async {
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
    _apiClient.clearToken();

    await _legacyApiService.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('Auth Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<void> _handleUnauthorized() async {
    if (!_isAuthenticated && _token == null) return;
    await _clearCredentials();
  }

  void _restoreCachedUser(String savedUserJson) {
    try {
      final decoded = jsonDecode(savedUserJson);
      if (decoded is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(decoded);
      }
    } catch (_) {
      _currentUser = null;
    }
  }
}
