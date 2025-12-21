import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../config/constants.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class ActivityLogService {
  static final ActivityLogService _instance = ActivityLogService._internal();
  factory ActivityLogService() => _instance;
  ActivityLogService._internal();

  static const String _offlineLogsBox = 'offline_activity_logs';
  static const String _currentActivityKey = 'current_activity';

  Box? _offlineBox;
  String? _currentActivityId;
  // ignore: unused_field
  DateTime? _currentActivityStartTime;
  String? _currentScreen;
  String? _previousScreen;
  Timer? _durationTimer;
  final _uuid = const Uuid();

  // Device info cache
  Map<String, dynamic>? _deviceInfo;

  // Initialize
  Future<void> initialize() async {
    _offlineBox = await Hive.openBox(_offlineLogsBox);
    await _loadDeviceInfo();

    // Sync offline logs on init
    _syncOfflineLogs();

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncOfflineLogs();
      }
    });
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceInfo = {
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'os': 'Android',
          'os_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceInfo = {
          'model': iosInfo.model,
          'name': iosInfo.name,
          'os': 'iOS',
          'os_version': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      print('Load device info error: $e');
    }
  }

  Future<String> _getConnectionType() async {
    try {
      final results = await Connectivity().checkConnectivity();

      if (results.contains(ConnectivityResult.wifi)) {
        return 'wifi';
      } else if (results.contains(ConnectivityResult.mobile)) {
        return 'mobile';
      } else if (results.contains(ConnectivityResult.none)) {
        return 'offline';
      } else {
        return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  // ==================== MAIN LOGGING METHODS ====================

  /// Log a simple activity (no duration tracking)
  Future<void> logActivity({
    required String activityType,
    String? resourceType,
    String? resourceId,
    String? resourceTitle,
    String? actionDetail,
    String? screenName,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final localId = _uuid.v4();
    final connectionType = await _getConnectionType();

    final data = {
      'user_id': user.id,
      'activity_type': activityType,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'resource_title': resourceTitle,
      'action_detail': actionDetail,
      'screen_name': screenName ?? _currentScreen,
      'previous_screen': _previousScreen,
      'started_at': now.toIso8601String(),
      'device_info': _deviceInfo,
      'connection_type': connectionType,
      'local_id': localId,
      ...?additionalData,
    };

    await _saveLog(data, localId);
  }

  /// Start tracking an activity with duration
  Future<String?> startActivity({
    required String activityType,
    String? resourceType,
    String? resourceId,
    String? resourceTitle,
    String? screenName,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return null;

    // End previous activity if exists
    await endCurrentActivity();

    final now = DateTime.now();
    final localId = _uuid.v4();
    final connectionType = await _getConnectionType();

    _currentActivityId = localId;
    _currentActivityStartTime = now;

    final data = {
      'user_id': user.id,
      'activity_type': activityType,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'resource_title': resourceTitle,
      'screen_name': screenName ?? _currentScreen,
      'previous_screen': _previousScreen,
      'started_at': now.toIso8601String(),
      'device_info': _deviceInfo,
      'connection_type': connectionType,
      'local_id': localId,
      'is_synced': false,
    };

    // Save to local storage for duration tracking
    await _offlineBox?.put(_currentActivityKey, data);

    return localId;
  }

  /// End current activity and record duration
  Future<void> endCurrentActivity({
    int? scrollDepthPercent,
    int? videoWatchPercent,
    List<int>? pdfPagesViewed,
    int? quizScore,
    int? quizTotalQuestions,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentActivityId == null) return;

    final storedData = _offlineBox?.get(_currentActivityKey);
    if (storedData == null) return;

    final now = DateTime.now();
    final data = Map<String, dynamic>.from(storedData);

    data['ended_at'] = now.toIso8601String();

    if (scrollDepthPercent != null) {
      data['scroll_depth_percent'] = scrollDepthPercent;
    }
    if (videoWatchPercent != null) {
      data['video_watch_percent'] = videoWatchPercent;
    }
    if (pdfPagesViewed != null) {
      data['pdf_pages_viewed'] = pdfPagesViewed;
    }
    if (quizScore != null) {
      data['quiz_score'] = quizScore;
    }
    if (quizTotalQuestions != null) {
      data['quiz_total_questions'] = quizTotalQuestions;
    }
    if (additionalData != null) {
      data.addAll(additionalData);
    }

    await _saveLog(data, _currentActivityId!);

    // Clear current activity
    _currentActivityId = null;
    _currentActivityStartTime = null;
    await _offlineBox?.delete(_currentActivityKey);
  }

  /// Update current activity without ending it
  Future<void> updateCurrentActivity({
    int? scrollDepthPercent,
    int? videoWatchPercent,
    List<int>? pdfPagesViewed,
    String? actionDetail,
  }) async {
    final storedData = _offlineBox?.get(_currentActivityKey);
    if (storedData == null) return;

    final data = Map<String, dynamic>.from(storedData);

    if (scrollDepthPercent != null) {
      data['scroll_depth_percent'] = scrollDepthPercent;
    }
    if (videoWatchPercent != null) {
      data['video_watch_percent'] = videoWatchPercent;
    }
    if (pdfPagesViewed != null) {
      data['pdf_pages_viewed'] = pdfPagesViewed;
    }
    if (actionDetail != null) {
      data['action_detail'] = actionDetail;
    }

    await _offlineBox?.put(_currentActivityKey, data);
  }

  // ==================== SPECIFIC ACTIVITY LOGGERS ====================

  /// Log login activity
  Future<void> logLogin() async {
    await logActivity(
      activityType: AppConstants.activityLogin,
      screenName: 'login_screen',
    );
  }

  /// Log logout activity
  Future<void> logLogout() async {
    await endCurrentActivity();
    await logActivity(
      activityType: AppConstants.activityLogout,
    );
  }

  /// Log navigation between screens
  Future<void> logNavigation(String fromScreen, String toScreen) async {
    _previousScreen = fromScreen;
    _currentScreen = toScreen;

    await logActivity(
      activityType: AppConstants.activityNavigate,
      screenName: toScreen,
      actionDetail: 'from: $fromScreen, to: $toScreen',
    );
  }

  /// Log button click
  Future<void> logButtonClick({
    required String buttonId,
    String? screenName,
    double? x,
    double? y,
  }) async {
    await logActivity(
      activityType: AppConstants.activityClickButton,
      actionDetail: buttonId,
      screenName: screenName,
      additionalData: x != null && y != null
          ? {
              'click_position': {'x': x, 'y': y}
            }
          : null,
    );
  }

  /// Log search activity
  Future<void> logSearch({
    required String query,
    required int resultsCount,
    String? screenName,
  }) async {
    await logActivity(
      activityType: AppConstants.activitySearch,
      screenName: screenName,
      additionalData: {
        'search_query': query,
        'search_results_count': resultsCount,
      },
    );
  }

  /// Start viewing a module
  Future<String?> startViewingModule({
    required String moduleId,
    required String moduleTitle,
    required String category,
  }) async {
    String activityType;
    switch (category) {
      case 'module':
        activityType = AppConstants.activityViewModule;
        break;
      case 'animation':
        activityType = AppConstants.activityViewAnimation;
        break;
      case 'meca_aid':
        activityType = AppConstants.activityViewMecaAid;
        break;
      default:
        activityType = AppConstants.activityViewModule;
    }

    return await startActivity(
      activityType: activityType,
      resourceType: category,
      resourceId: moduleId,
      resourceTitle: moduleTitle,
    );
  }

  /// Start viewing error code
  Future<String?> startViewingErrorCode({
    required String errorCodeId,
    required String errorCode,
  }) async {
    return await startActivity(
      activityType: AppConstants.activityViewErrorCode,
      resourceType: AppConstants.resourceErrorCode,
      resourceId: errorCodeId,
      resourceTitle: errorCode,
    );
  }

  /// Log quiz start
  Future<void> logQuizStart({
    required String moduleId,
    required String moduleTitle,
  }) async {
    await logActivity(
      activityType: AppConstants.activityStartQuiz,
      resourceType: AppConstants.resourceMecaAid,
      resourceId: moduleId,
      resourceTitle: moduleTitle,
    );
  }

  /// Log answer submission
  Future<void> logAnswerSubmission({
    required String questionId,
    required String moduleId,
    required bool isCorrect,
    required int timeSpentSeconds,
  }) async {
    await logActivity(
      activityType: AppConstants.activitySubmitAnswer,
      resourceType: AppConstants.resourceQuestion,
      resourceId: questionId,
      additionalData: {
        'is_correct': isCorrect,
        'time_spent_seconds': timeSpentSeconds,
      },
    );
  }

  /// Log quiz completion
  Future<void> logQuizComplete({
    required String moduleId,
    required String moduleTitle,
    required int score,
    required int totalQuestions,
    required int totalTimeSeconds,
  }) async {
    await logActivity(
      activityType: AppConstants.activityCompleteQuiz,
      resourceType: AppConstants.resourceMecaAid,
      resourceId: moduleId,
      resourceTitle: moduleTitle,
      additionalData: {
        'quiz_score': score,
        'quiz_total_questions': totalQuestions,
        'duration_seconds': totalTimeSeconds,
      },
    );
  }

  // ==================== OFFLINE SYNC ====================

  Future<void> _saveLog(Map<String, dynamic> data, String localId) async {
    final connectionType = await _getConnectionType();

    if (connectionType == 'offline') {
      // Save to offline storage
      data['is_synced'] = false;
      await _offlineBox?.put(localId, data);
    } else {
      // Try to save online
      try {
        data['is_synced'] = true;
        final success = await SupabaseService.logActivity(data);
        if (!success) {
          // Save to offline if failed
          data['is_synced'] = false;
          await _offlineBox?.put(localId, data);
        }
      } catch (e) {
        // Save to offline on error
        data['is_synced'] = false;
        await _offlineBox?.put(localId, data);
      }
    }
  }

  Future<void> _syncOfflineLogs() async {
    if (_offlineBox == null) return;

    final keys =
        _offlineBox!.keys.where((k) => k != _currentActivityKey).toList();

    for (final key in keys) {
      final data = _offlineBox!.get(key);
      if (data == null) continue;

      final logData = Map<String, dynamic>.from(data);
      if (logData['is_synced'] == true) {
        await _offlineBox!.delete(key);
        continue;
      }

      try {
        logData['is_synced'] = true;
        final success = await SupabaseService.logActivity(logData);
        if (success) {
          await _offlineBox!.delete(key);
        }
      } catch (e) {
        print('Sync log error: $e');
      }
    }
  }

  /// Get current screen name
  String? get currentScreen => _currentScreen;

  /// Set current screen
  void setCurrentScreen(String screen) {
    _previousScreen = _currentScreen;
    _currentScreen = screen;
  }

  /// Get offline logs count
  int get offlineLogsCount {
    if (_offlineBox == null) return 0;
    return _offlineBox!.keys.where((k) => k != _currentActivityKey).length;
  }

  /// Force sync offline logs
  Future<void> forceSyncOfflineLogs() async {
    await _syncOfflineLogs();
  }

  /// Dispose resources
  void dispose() {
    _durationTimer?.cancel();
    endCurrentActivity();
  }
}
