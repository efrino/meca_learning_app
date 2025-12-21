import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../config/constants.dart';
import '../../shared/models/user_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Hash password
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ==================== AUTH ====================

  // Login with NRP and Password
  static Future<UserModel?> login(String nrp, String password) async {
    try {
      final hashedPassword = hashPassword(password);

      final response = await client
          .from('users')
          .select()
          .eq('nrp', nrp.toUpperCase())
          .eq('password', hashedPassword)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        // Try with plain password for initial setup
        final plainResponse = await client
            .from('users')
            .select()
            .eq('nrp', nrp.toUpperCase())
            .eq('password', password)
            .eq('is_active', true)
            .maybeSingle();

        if (plainResponse != null) {
          // Update to hashed password
          await client.from('users').update({'password': hashedPassword}).eq(
              'id', plainResponse['id']);

          // Update last login
          await client
              .from('users')
              .update({'last_login_at': DateTime.now().toIso8601String()}).eq(
                  'id', plainResponse['id']);

          return UserModel.fromJson(plainResponse);
        }
        return null;
      }

      // Update last login
      await client
          .from('users')
          .update({'last_login_at': DateTime.now().toIso8601String()}).eq(
              'id', response['id']);

      return UserModel.fromJson(response);
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final response =
          await client.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // ==================== MODULES ====================

  static Future<List<Map<String, dynamic>>> getModules({
    String? category,
    bool activeOnly = true,
  }) async {
    try {
      var query = client.from('modules').select();

      if (category != null) {
        query = query.eq('category', category);
      }

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('order_index');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get modules error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getModuleById(String id) async {
    try {
      final response =
          await client.from('modules').select().eq('id', id).maybeSingle();
      return response;
    } catch (e) {
      print('Get module error: $e');
      return null;
    }
  }

  static Future<bool> createModule(Map<String, dynamic> data) async {
    try {
      await client.from('modules').insert(data);
      return true;
    } catch (e) {
      print('Create module error: $e');
      return false;
    }
  }

  static Future<bool> updateModule(String id, Map<String, dynamic> data) async {
    try {
      await client.from('modules').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Update module error: $e');
      return false;
    }
  }

  static Future<bool> deleteModule(String id) async {
    try {
      await client.from('modules').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Delete module error: $e');
      return false;
    }
  }

  // ==================== ERROR CODES ====================

  static Future<List<Map<String, dynamic>>> getErrorCodes({
    String? category,
    String? machineType,
    bool activeOnly = true,
  }) async {
    try {
      var query = client.from('error_codes').select('''
        *,
        error_code_images(*)
      ''');

      if (category != null) {
        query = query.eq('category', category);
      }

      if (machineType != null) {
        query = query.eq('machine_type', machineType);
      }

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('code');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get error codes error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getErrorCodeById(String id) async {
    try {
      final response = await client.from('error_codes').select('''
            *,
            error_code_images(*)
          ''').eq('id', id).maybeSingle();
      return response;
    } catch (e) {
      print('Get error code error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> searchErrorCodes(
      String query) async {
    try {
      final response = await client
          .from('error_codes')
          .select('''
            *,
            error_code_images(*)
          ''')
          .or('code.ilike.%$query%,title.ilike.%$query%,cause.ilike.%$query%,solution.ilike.%$query%')
          .eq('is_active', true)
          .order('code');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Search error codes error: $e');
      return [];
    }
  }

  static Future<bool> createErrorCode(Map<String, dynamic> data) async {
    try {
      await client.from('error_codes').insert(data);
      return true;
    } catch (e) {
      print('Create error code error: $e');
      return false;
    }
  }

  static Future<bool> updateErrorCode(
      String id, Map<String, dynamic> data) async {
    try {
      await client.from('error_codes').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Update error code error: $e');
      return false;
    }
  }

  // ==================== QUESTIONS ====================

  static Future<List<Map<String, dynamic>>> getQuestionsByModuleId(
    String moduleId,
  ) async {
    try {
      final response = await client
          .from('questions')
          .select()
          .eq('module_id', moduleId)
          .eq('is_active', true)
          .order('order_index');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get questions error: $e');
      return [];
    }
  }

  static Future<bool> createQuestion(Map<String, dynamic> data) async {
    try {
      await client.from('questions').insert(data);
      return true;
    } catch (e) {
      print('Create question error: $e');
      return false;
    }
  }

  static Future<bool> updateQuestion(
      String id, Map<String, dynamic> data) async {
    try {
      await client.from('questions').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Update question error: $e');
      return false;
    }
  }

  static Future<bool> deleteQuestion(String id) async {
    try {
      await client.from('questions').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Delete question error: $e');
      return false;
    }
  }

  // ==================== USER ANSWERS ====================

  static Future<bool> submitAnswer(Map<String, dynamic> data) async {
    try {
      await client.from('user_answers').insert(data);
      return true;
    } catch (e) {
      print('Submit answer error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserAnswers(
    String userId,
    String moduleId,
  ) async {
    try {
      final response = await client
          .from('user_answers')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .order('answered_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get user answers error: $e');
      return [];
    }
  }

  // ==================== ACTIVITY LOGS ====================

  static Future<bool> logActivity(Map<String, dynamic> data) async {
    try {
      await client.from('activity_logs').insert(data);
      return true;
    } catch (e) {
      print('Log activity error: $e');
      return false;
    }
  }

  static Future<bool> updateActivityLog(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await client.from('activity_logs').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Update activity log error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getActivityLogs({
    String? userId,
    String? activityType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = client.from('activity_logs').select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (activityType != null) {
        query = query.eq('activity_type', activityType);
      }

      if (startDate != null) {
        query = query.gte('started_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('started_at', endDate.toIso8601String());
      }

      final response =
          await query.order('started_at', ascending: false).limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get activity logs error: $e');
      return [];
    }
  }

  // ==================== USER PROGRESS ====================

  static Future<Map<String, dynamic>?> getUserProgress(
    String userId,
    String moduleId,
  ) async {
    try {
      final response = await client
          .from('user_progress')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get user progress error: $e');
      return null;
    }
  }

  static Future<bool> upsertUserProgress(Map<String, dynamic> data) async {
    try {
      await client.from('user_progress').upsert(
            data,
            onConflict: 'user_id,module_id',
          );
      return true;
    } catch (e) {
      print('Upsert user progress error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUserProgress(
    String userId,
  ) async {
    try {
      final response = await client
          .from('user_progress')
          .select('''
            *,
            modules(*)
          ''')
          .eq('user_id', userId)
          .order('last_accessed_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get all user progress error: $e');
      return [];
    }
  }

  // ==================== USERS MANAGEMENT (Admin) ====================

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }

  static Future<bool> createUser(Map<String, dynamic> data) async {
    try {
      // Hash password
      if (data['password'] != null) {
        data['password'] = hashPassword(data['password']);
      }
      await client.from('users').insert(data);
      return true;
    } catch (e) {
      print('Create user error: $e');
      return false;
    }
  }

  static Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      // Hash password if provided
      if (data['password'] != null) {
        data['password'] = hashPassword(data['password']);
      }
      await client.from('users').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Update user error: $e');
      return false;
    }
  }

  static Future<bool> deleteUser(String id) async {
    try {
      await client.from('users').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Delete user error: $e');
      return false;
    }
  }

  // ==================== FCM TOKENS ====================

  static Future<bool> saveFcmToken(
    String userId,
    String token,
    String deviceId,
    String platform,
  ) async {
    try {
      await client.from('user_fcm_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'device_id': deviceId,
          'platform': platform,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,device_id',
      );
      return true;
    } catch (e) {
      print('Save FCM token error: $e');
      return false;
    }
  }

  static Future<List<String>> getActiveFcmTokens() async {
    try {
      final response = await client
          .from('user_fcm_tokens')
          .select('fcm_token')
          .eq('is_active', true);
      return (response as List).map((e) => e['fcm_token'] as String).toList();
    } catch (e) {
      print('Get FCM tokens error: $e');
      return [];
    }
  }

  // ==================== CONTENT UPDATES ====================

  static Future<bool> createContentUpdate(Map<String, dynamic> data) async {
    try {
      await client.from('content_updates').insert(data);
      return true;
    } catch (e) {
      print('Create content update error: $e');
      return false;
    }
  }

  // ==================== ANALYTICS (Admin) ====================

  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      // Get total users
      final usersResponse =
          await client.from('users').select().eq('is_active', true);
      final totalUsers = (usersResponse as List).length;

      // Get total modules
      final modulesResponse =
          await client.from('modules').select().eq('is_active', true);
      final totalModules = (modulesResponse as List).length;

      // Get total error codes
      final errorCodesResponse =
          await client.from('error_codes').select().eq('is_active', true);
      final totalErrorCodes = (errorCodesResponse as List).length;

      // Get today's activity count
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final activityResponse = await client
          .from('activity_logs')
          .select()
          .gte('started_at', startOfDay.toIso8601String());
      final todayActivities = (activityResponse as List).length;

      // Get active users today
      final activeUsersResponse = await client
          .from('activity_logs')
          .select('user_id')
          .gte('started_at', startOfDay.toIso8601String());
      final activeUsersToday =
          (activeUsersResponse as List).map((e) => e['user_id']).toSet().length;

      return {
        'total_users': totalUsers,
        'total_modules': totalModules,
        'total_error_codes': totalErrorCodes,
        'today_activities': todayActivities,
        'active_users_today': activeUsersToday,
      };
    } catch (e) {
      print('Get analytics error: $e');
      return {};
    }
  }
}
