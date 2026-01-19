import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';
import '../../shared/models/user_model.dart';
import 'supabase_service.dart';
import 'activity_log_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserModel? _currentUser;
  String? _sessionToken;

  UserModel? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Initialize auth service - check for saved session
  Future<bool> initialize() async {
    try {
      final savedUser = await _secureStorage.read(key: AppConstants.userKey);
      final savedToken = await _secureStorage.read(key: AppConstants.tokenKey);

      if (savedUser != null && savedToken != null) {
        final userMap = jsonDecode(savedUser) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
        _sessionToken = savedToken;

        // Verify user still exists and is active
        final freshUser = await SupabaseService.getUserById(_currentUser!.id);
        if (freshUser != null && freshUser.isActive) {
          _currentUser = freshUser;

          // Set current user ID untuk quiz system
          SupabaseService.setCurrentUserId(freshUser.id);

          return true;
        } else {
          // User not found or inactive, clear session
          await logout();
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Auth initialize error: $e');
      return false;
    }
  }

  /// Login with NRP and password
  Future<LoginResult> login(String nrp, String password) async {
    try {
      if (nrp.isEmpty) {
        return LoginResult.error('NRP tidak boleh kosong');
      }
      if (password.isEmpty) {
        return LoginResult.error('Password tidak boleh kosong');
      }

      final user = await SupabaseService.login(nrp, password);

      if (user == null) {
        return LoginResult.error('NRP atau password salah');
      }

      if (!user.isActive) {
        return LoginResult.error(
            'Akun Anda tidak aktif. Hubungi administrator.');
      }

      // Generate session token
      _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
      _currentUser = user;

      // Set current user ID untuk quiz system
      SupabaseService.setCurrentUserId(user.id);

      // Save to secure storage
      await _secureStorage.write(
        key: AppConstants.userKey,
        value: jsonEncode(user.toJson()),
      );
      await _secureStorage.write(
        key: AppConstants.tokenKey,
        value: _sessionToken,
      );

      // Log login activity
      await ActivityLogService().logLogin();

      return LoginResult.success(user);
    } catch (e) {
      print('Login error: $e');
      return LoginResult.error('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  /// Logout
  Future<void> logout() async {
    // Log logout activity before clearing user
    if (_currentUser != null) {
      await ActivityLogService().logLogout();
    }

    _currentUser = null;
    _sessionToken = null;

    // Clear current user ID dari SupabaseService
    SupabaseService.setCurrentUserId(null);

    await _secureStorage.delete(key: AppConstants.userKey);
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    final freshUser = await SupabaseService.getUserById(_currentUser!.id);
    if (freshUser != null) {
      _currentUser = freshUser;

      // Update current user ID jika berubah (seharusnya tidak, tapi untuk safety)
      SupabaseService.setCurrentUserId(freshUser.id);

      await _secureStorage.write(
        key: AppConstants.userKey,
        value: jsonEncode(freshUser.toJson()),
      );
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? department,
    String? position,
  }) async {
    if (_currentUser == null) return false;

    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (department != null) data['department'] = department;
    if (position != null) data['position'] = position;

    if (data.isEmpty) return true;

    final success = await SupabaseService.updateUser(_currentUser!.id, data);
    if (success) {
      await refreshUser();
    }
    return success;
  }

  /// Change password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    // Verify current password
    final user =
        await SupabaseService.login(_currentUser!.nrp, currentPassword);
    if (user == null) return false;

    // Update password
    return await SupabaseService.updateUser(_currentUser!.id, {
      'password': newPassword,
    });
  }
}

class LoginResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;

  LoginResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory LoginResult.success(UserModel user) {
    return LoginResult._(isSuccess: true, user: user);
  }

  factory LoginResult.error(String message) {
    return LoginResult._(isSuccess: false, errorMessage: message);
  }
}
