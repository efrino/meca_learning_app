import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // untuk debugPrint
import '../../config/constants.dart';
import '../../shared/models/user_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ==================== CURRENT USER ID ====================
  static String? _currentUserId;

  static String? get currentUserId => _currentUserId;

  /// Set current user ID (panggil setelah login)
  static void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

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

          // Set current user ID
          setCurrentUserId(plainResponse['id']);

          return UserModel.fromJson(plainResponse);
        }
        return null;
      }

      // Update last login
      await client
          .from('users')
          .update({'last_login_at': DateTime.now().toIso8601String()}).eq(
              'id', response['id']);

      // Set current user ID
      setCurrentUserId(response['id']);

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // Logout - clear current user
  static void logout() {
    setCurrentUserId(null);
  }

  // Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final response =
          await client.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Get user error: $e');
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
      debugPrint('Get modules error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getModuleById(String id) async {
    try {
      final response =
          await client.from('modules').select().eq('id', id).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Get module error: $e');
      return null;
    }
  }

  static Future<bool> createModule(Map<String, dynamic> data) async {
    try {
      await client.from('modules').insert(data);
      return true;
    } catch (e) {
      debugPrint('Create module error: $e');
      return false;
    }
  }

  static Future<bool> updateModule(String id, Map<String, dynamic> data) async {
    try {
      await client.from('modules').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Update module error: $e');
      return false;
    }
  }

  static Future<bool> deleteModule(String id) async {
    try {
      await client.from('modules').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Delete module error: $e');
      return false;
    }
  }

  /// Mengambil modules berdasarkan parent_folder_id (gdrive_folder_id)
  // static Future<List<Map<String, dynamic>>> getModulesByFolder(
  //     String folderId) async {
  //   try {
  //     final response = await client
  //         .from('modules')
  //         .select()
  //         .eq('parent_folder_id', folderId)
  //         .eq('is_active', true)
  //         .order('order_index', ascending: true)
  //         .order('title', ascending: true);
  //     return List<Map<String, dynamic>>.from(response);
  //   } catch (e) {
  //     debugPrint('Error getModulesByFolder: $e');
  //     rethrow;
  //   }
  // }

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
      debugPrint('Get error codes error: $e');
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
      debugPrint('Get error code error: $e');
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
      debugPrint('Search error codes error: $e');
      return [];
    }
  }

  static Future<bool> createErrorCode(Map<String, dynamic> data) async {
    try {
      await client.from('error_codes').insert(data);
      return true;
    } catch (e) {
      debugPrint('Create error code error: $e');
      return false;
    }
  }

  static Future<bool> updateErrorCode(
      String id, Map<String, dynamic> data) async {
    try {
      await client.from('error_codes').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Update error code error: $e');
      return false;
    }
  }

  // ==================== QUESTIONS ====================

  /// Mengambil soal-soal berdasarkan module_id
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

      // Safely convert response to List<Map<String, dynamic>>
      return response.map((item) {
        return item;
      }).toList();
    } catch (e) {
      debugPrint('Get questions error: $e');
      return [];
    }
  }

  /// Mengambil soal-soal berdasarkan quiz_id
  static Future<List<Map<String, dynamic>>> getQuestionsByQuizId(
      String quizId) async {
    try {
      final response = await client
          .from('questions')
          .select()
          .eq('quiz_id', quizId)
          .eq('is_active', true)
          .order('order_index', ascending: true);

      // Safely convert response to List<Map<String, dynamic>>
      return response.map((item) {
        return item;
      }).toList();
    } catch (e) {
      debugPrint('Error getQuestionsByQuizId: $e');
      rethrow;
    }
  }

  /// Membuat soal baru (simple)
  static Future<bool> createQuestion(Map<String, dynamic> data) async {
    try {
      await client.from('questions').insert(data);
      return true;
    } catch (e) {
      debugPrint('Create question error: $e');
      return false;
    }
  }

  /// Membuat soal baru dengan parameter lengkap (untuk Admin)
  static Future<Map<String, dynamic>> createQuestionWithDetails({
    required String quizId,
    required String questionText,
    required String correctAnswer,
    String? moduleId,
    String? questionImageGdriveId,
    String questionType = 'multiple_choice',
    List<Map<String, dynamic>>? options,
    String? explanation,
    int points = 10,
    int orderIndex = 0,
  }) async {
    try {
      final response = await client
          .from('questions')
          .insert({
            'quiz_id': quizId,
            'module_id': moduleId,
            'question_text': questionText,
            'question_image_gdrive_id': questionImageGdriveId,
            'question_type': questionType,
            'options': options,
            'correct_answer': correctAnswer,
            'explanation': explanation,
            'points': points,
            'order_index': orderIndex,
            'is_active': true,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('Error createQuestionWithDetails: $e');
      rethrow;
    }
  }

  static Future<bool> updateQuestion(
      String id, Map<String, dynamic> data) async {
    try {
      await client.from('questions').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Update question error: $e');
      return false;
    }
  }

  static Future<bool> deleteQuestion(String id) async {
    try {
      await client.from('questions').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Delete question error: $e');
      return false;
    }
  }

  // ==================== USER ANSWERS ====================

  static Future<bool> submitAnswer(Map<String, dynamic> data) async {
    try {
      await client.from('user_answers').insert(data);
      return true;
    } catch (e) {
      debugPrint('Submit answer error: $e');
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
      debugPrint('Get user answers error: $e');
      return [];
    }
  }

  /// Menyimpan jawaban user (untuk quiz system)
  static Future<void> saveUserAnswer({
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    String? moduleId,
    int attemptNumber = 1,
    int? timeSpentSeconds,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not logged in');

      await client.from('user_answers').insert({
        'user_id': userId,
        'question_id': questionId,
        'module_id': moduleId,
        'attempt_number': attemptNumber,
        'selected_answer': selectedAnswer,
        'is_correct': isCorrect,
        'time_spent_seconds': timeSpentSeconds,
      });
    } catch (e) {
      debugPrint('Error saveUserAnswer: $e');
      rethrow;
    }
  }

  /// Mengambil riwayat quiz user
  static Future<List<Map<String, dynamic>>> getUserQuizHistory({
    String? quizId,
    String? moduleId,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      var query = client
          .from('user_answers')
          .select('*, questions(*)')
          .eq('user_id', userId);

      if (moduleId != null) {
        query = query.eq('module_id', moduleId);
      }

      final response = await query.order('answered_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getUserQuizHistory: $e');
      return [];
    }
  }

  // ==================== ACTIVITY LOGS ====================

  static Future<bool> logActivity(Map<String, dynamic> data) async {
    try {
      await client.from('activity_logs').insert(data);
      return true;
    } catch (e) {
      debugPrint('Log activity error: $e');
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
      debugPrint('Update activity log error: $e');
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
      debugPrint('Get activity logs error: $e');
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
      debugPrint('Get user progress error: $e');
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
      debugPrint('Upsert user progress error: $e');
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
      debugPrint('Get all user progress error: $e');
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
      debugPrint('Get all users error: $e');
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
      debugPrint('Create user error: $e');
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
      debugPrint('Update user error: $e');
      return false;
    }
  }

  static Future<bool> deleteUser(String id) async {
    try {
      await client.from('users').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Delete user error: $e');
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
      debugPrint('Save FCM token error: $e');
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
      debugPrint('Get FCM tokens error: $e');
      return [];
    }
  }

  // ==================== CONTENT UPDATES ====================

  static Future<bool> createContentUpdate(Map<String, dynamic> data) async {
    try {
      await client.from('content_updates').insert(data);
      return true;
    } catch (e) {
      debugPrint('Create content update error: $e');
      return false;
    }
  }

  // ==================== MECA AID FOLDERS ====================
  /// Get all active Meca Aid folders
  static Future<List<Map<String, dynamic>>> getMecaAidFolders({
    bool activeOnly = true,
  }) async {
    try {
      var query = client.from('meca_aid_folders').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('order_index');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get meca aid folders error: $e');
      return [];
    }
  }

  /// Get modules by parent folder ID (meca_aid_folders.id UUID)
  /// parent_folder_id di modules = id di meca_aid_folders
  static Future<List<Map<String, dynamic>>> getModulesByFolder(
    String folderId, {
    bool activeOnly = true,
  }) async {
    try {
      var query = client
          .from('modules')
          .select()
          .eq('parent_folder_id', folderId)
          .eq('category', 'meca_aid'); // Filter category juga

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('order_index');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get modules by folder error: $e');
      return [];
    }
  }

  /// Create a new Meca Aid folder
  static Future<bool> createMecaAidFolder(Map<String, dynamic> data) async {
    try {
      await client.from('meca_aid_folders').insert(data);
      return true;
    } catch (e) {
      print('Create meca aid folder error: $e');
      return false;
    }
  }

  /// Update a Meca Aid folder
  static Future<bool> updateMecaAidFolder(
      String id, Map<String, dynamic> data) async {
    try {
      await client.from('meca_aid_folders').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Update meca aid folder error: $e');
      return false;
    }
  }

  /// Delete a Meca Aid folder
  static Future<bool> deleteMecaAidFolder(String id) async {
    try {
      await client.from('meca_aid_folders').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Delete meca aid folder error: $e');
      return false;
    }
  }

  /// Mengambil daftar folder Meca Aid dari tabel meca_aid_folders
  // static Future<List<Map<String, dynamic>>> getMecaAidFolders() async {
  //   try {
  //     final response = await client
  //         .from('meca_aid_folders')
  //         .select()
  //         .eq('is_active', true)
  //         .order('order_index', ascending: true)
  //         .order('folder_name', ascending: true);
  //     return List<Map<String, dynamic>>.from(response);
  //   } catch (e) {
  //     debugPrint('Error getMecaAidFolders: $e');
  //     rethrow;
  //   }
  // }

  /// Menghitung jumlah folder Meca Aid aktif
  static Future<int> countMecaAidFolders() async {
    try {
      final response = await client
          .from('meca_aid_folders')
          .select('id')
          .eq('is_active', true);
      return (response as List).length;
    } catch (e) {
      debugPrint('Error countMecaAidFolders: $e');
      return 0;
    }
  }

  /// Membuat folder Meca Aid baru
  // static Future<Map<String, dynamic>> createMecaAidFolder({
  //   required String gdriveFolderId,
  //   required String folderName,
  //   String? description,
  //   int orderIndex = 0,
  // }) async {
  //   try {
  //     final response = await client
  //         .from('meca_aid_folders')
  //         .insert({
  //           'gdrive_folder_id': gdriveFolderId,
  //           'folder_name': folderName,
  //           'description': description,
  //           'order_index': orderIndex,
  //           'is_active': true,
  //         })
  //         .select()
  //         .single();
  //     return response;
  //   } catch (e) {
  //     debugPrint('Error createMecaAidFolder: $e');
  //     rethrow;
  //   }
  // }

  // ==================== QUIZZES ====================

  /// Mengambil daftar quiz dari tabel quizzes
  static Future<List<Map<String, dynamic>>> getQuizzes({
    String? quizType,
  }) async {
    try {
      var query = client.from('quizzes').select().eq('is_active', true);

      if (quizType != null) {
        query = query.eq('quiz_type', quizType);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getQuizzes: $e');
      rethrow;
    }
  }

  /// Mengambil quiz berdasarkan ID
  static Future<Map<String, dynamic>?> getQuizById(String quizId) async {
    try {
      final response =
          await client.from('quizzes').select().eq('id', quizId).single();
      return response;
    } catch (e) {
      debugPrint('Error getQuizById: $e');
      return null;
    }
  }

  /// Menghitung jumlah quiz aktif
  static Future<int> countQuizzes({String? quizType}) async {
    try {
      var query = client.from('quizzes').select('id').eq('is_active', true);

      if (quizType != null) {
        query = query.eq('quiz_type', quizType);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      debugPrint('Error countQuizzes: $e');
      return 0;
    }
  }

  /// Membuat quiz baru
  static Future<Map<String, dynamic>> createQuiz({
    required String title,
    String? description,
    String quizType = 'quiz',
    String? moduleId,
    String? sourceGdriveId,
    String? sourceGdriveName,
    int? timeLimitMinutes,
    int passingScore = 70,
    int? maxAttempts,
    bool shuffleQuestions = false,
    bool shuffleOptions = false,
    bool showCorrectAnswers = true,
  }) async {
    try {
      final response = await client
          .from('quizzes')
          .insert({
            'title': title,
            'description': description,
            'quiz_type': quizType,
            'module_id': moduleId,
            'source_gdrive_id': sourceGdriveId,
            'source_gdrive_name': sourceGdriveName,
            'time_limit_minutes': timeLimitMinutes,
            'passing_score': passingScore,
            'max_attempts': maxAttempts,
            'shuffle_questions': shuffleQuestions,
            'shuffle_options': shuffleOptions,
            'show_correct_answers': showCorrectAnswers,
            'is_active': true,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('Error createQuiz: $e');
      rethrow;
    }
  }

  /// Update jumlah total soal pada quiz
  static Future<void> updateQuizTotalQuestions(String quizId) async {
    try {
      final questions = await getQuestionsByQuizId(quizId);
      await client.from('quizzes').update({
        'total_questions': questions.length,
      }).eq('id', quizId);
    } catch (e) {
      debugPrint('Error updateQuizTotalQuestions: $e');
      rethrow;
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
      debugPrint('Get analytics error: $e');
      return {};
    }
  }
}
