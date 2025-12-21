class ActivityLogModel {
  final String id;
  final String userId;
  final String? sessionId;

  // Activity Info
  final String activityType;
  final String? resourceType;
  final String? resourceId;
  final String? resourceTitle;

  // Timing
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  // Behavior Details
  final String? actionDetail;
  final String? screenName;
  final String? previousScreen;

  // Interaction Metrics
  final int? scrollDepthPercent;
  final int? videoWatchPercent;
  final List<int>? pdfPagesViewed;
  final Map<String, dynamic>? clickPosition;

  // Quiz Specific
  final int? quizScore;
  final int? quizTotalQuestions;

  // Search Specific
  final String? searchQuery;
  final int? searchResultsCount;

  // Device & Connection Info
  final Map<String, dynamic>? deviceInfo;
  final String? ipAddress;
  final String? connectionType;

  // Offline Sync
  final bool isSynced;
  final String? localId;

  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.userId,
    this.sessionId,
    required this.activityType,
    this.resourceType,
    this.resourceId,
    this.resourceTitle,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.actionDetail,
    this.screenName,
    this.previousScreen,
    this.scrollDepthPercent,
    this.videoWatchPercent,
    this.pdfPagesViewed,
    this.clickPosition,
    this.quizScore,
    this.quizTotalQuestions,
    this.searchQuery,
    this.searchResultsCount,
    this.deviceInfo,
    this.ipAddress,
    this.connectionType,
    this.isSynced = true,
    this.localId,
    required this.createdAt,
  });

  String get activityTypeLabel {
    switch (activityType) {
      case 'login':
        return 'Login';
      case 'logout':
        return 'Logout';
      case 'view_module':
        return 'Melihat Modul';
      case 'view_animation':
        return 'Melihat Animasi';
      case 'view_meca_aid':
        return 'Melihat Meca Aid';
      case 'start_quiz':
        return 'Memulai Quiz';
      case 'submit_answer':
        return 'Menjawab Soal';
      case 'complete_quiz':
        return 'Menyelesaikan Quiz';
      case 'view_error_code':
        return 'Melihat Error Code';
      case 'search':
        return 'Pencarian';
      case 'navigate':
        return 'Navigasi';
      case 'click_button':
        return 'Klik Tombol';
      default:
        return activityType;
    }
  }

  String get durationLabel {
    if (durationSeconds == null) return '-';
    if (durationSeconds! < 60) {
      return '$durationSeconds detik';
    } else if (durationSeconds! < 3600) {
      final minutes = durationSeconds! ~/ 60;
      final seconds = durationSeconds! % 60;
      return '$minutes menit $seconds detik';
    } else {
      final hours = durationSeconds! ~/ 3600;
      final minutes = (durationSeconds! % 3600) ~/ 60;
      return '$hours jam $minutes menit';
    }
  }

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    List<int>? pdfPagesViewed;
    if (json['pdf_pages_viewed'] != null) {
      pdfPagesViewed = List<int>.from(json['pdf_pages_viewed'] as List);
    }

    Map<String, dynamic>? clickPosition;
    if (json['click_position'] != null) {
      clickPosition = Map<String, dynamic>.from(json['click_position'] as Map);
    }

    Map<String, dynamic>? deviceInfo;
    if (json['device_info'] != null) {
      deviceInfo = Map<String, dynamic>.from(json['device_info'] as Map);
    }

    return ActivityLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sessionId: json['session_id'] as String?,
      activityType: json['activity_type'] as String,
      resourceType: json['resource_type'] as String?,
      resourceId: json['resource_id'] as String?,
      resourceTitle: json['resource_title'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      actionDetail: json['action_detail'] as String?,
      screenName: json['screen_name'] as String?,
      previousScreen: json['previous_screen'] as String?,
      scrollDepthPercent: json['scroll_depth_percent'] as int?,
      videoWatchPercent: json['video_watch_percent'] as int?,
      pdfPagesViewed: pdfPagesViewed,
      clickPosition: clickPosition,
      quizScore: json['quiz_score'] as int?,
      quizTotalQuestions: json['quiz_total_questions'] as int?,
      searchQuery: json['search_query'] as String?,
      searchResultsCount: json['search_results_count'] as int?,
      deviceInfo: deviceInfo,
      ipAddress: json['ip_address'] as String?,
      connectionType: json['connection_type'] as String?,
      isSynced: json['is_synced'] as bool? ?? true,
      localId: json['local_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'activity_type': activityType,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'resource_title': resourceTitle,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'action_detail': actionDetail,
      'screen_name': screenName,
      'previous_screen': previousScreen,
      'scroll_depth_percent': scrollDepthPercent,
      'video_watch_percent': videoWatchPercent,
      'pdf_pages_viewed': pdfPagesViewed,
      'click_position': clickPosition,
      'quiz_score': quizScore,
      'quiz_total_questions': quizTotalQuestions,
      'search_query': searchQuery,
      'search_results_count': searchResultsCount,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'connection_type': connectionType,
      'is_synced': isSynced,
      'local_id': localId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'session_id': sessionId,
      'activity_type': activityType,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'resource_title': resourceTitle,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'action_detail': actionDetail,
      'screen_name': screenName,
      'previous_screen': previousScreen,
      'scroll_depth_percent': scrollDepthPercent,
      'video_watch_percent': videoWatchPercent,
      'pdf_pages_viewed': pdfPagesViewed,
      'click_position': clickPosition,
      'quiz_score': quizScore,
      'quiz_total_questions': quizTotalQuestions,
      'search_query': searchQuery,
      'search_results_count': searchResultsCount,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'connection_type': connectionType,
      'is_synced': isSynced,
      'local_id': localId,
    };
  }
}

class UserProgressModel {
  final String id;
  final String userId;
  final String moduleId;
  final int progressPercentage;
  final String? lastPosition;
  final int totalTimeSpentSeconds;
  final int viewCount;
  final int? quizBestScore;
  final int quizAttempts;
  final DateTime? quizLastAttemptAt;
  final DateTime firstAccessedAt;
  final DateTime lastAccessedAt;
  final DateTime? completedAt;

  UserProgressModel({
    required this.id,
    required this.userId,
    required this.moduleId,
    this.progressPercentage = 0,
    this.lastPosition,
    this.totalTimeSpentSeconds = 0,
    this.viewCount = 1,
    this.quizBestScore,
    this.quizAttempts = 0,
    this.quizLastAttemptAt,
    required this.firstAccessedAt,
    required this.lastAccessedAt,
    this.completedAt,
  });

  bool get isCompleted => completedAt != null;

  String get timeSpentLabel {
    if (totalTimeSpentSeconds < 60) {
      return '$totalTimeSpentSeconds detik';
    } else if (totalTimeSpentSeconds < 3600) {
      final minutes = totalTimeSpentSeconds ~/ 60;
      return '$minutes menit';
    } else {
      final hours = totalTimeSpentSeconds ~/ 3600;
      final minutes = (totalTimeSpentSeconds % 3600) ~/ 60;
      return '$hours jam $minutes menit';
    }
  }

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moduleId: json['module_id'] as String,
      progressPercentage: json['progress_percentage'] as int? ?? 0,
      lastPosition: json['last_position'] as String?,
      totalTimeSpentSeconds: json['total_time_spent_seconds'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 1,
      quizBestScore: json['quiz_best_score'] as int?,
      quizAttempts: json['quiz_attempts'] as int? ?? 0,
      quizLastAttemptAt: json['quiz_last_attempt_at'] != null
          ? DateTime.parse(json['quiz_last_attempt_at'] as String)
          : null,
      firstAccessedAt: DateTime.parse(json['first_accessed_at'] as String),
      lastAccessedAt: DateTime.parse(json['last_accessed_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'module_id': moduleId,
      'progress_percentage': progressPercentage,
      'last_position': lastPosition,
      'total_time_spent_seconds': totalTimeSpentSeconds,
      'view_count': viewCount,
      'quiz_best_score': quizBestScore,
      'quiz_attempts': quizAttempts,
      'quiz_last_attempt_at': quizLastAttemptAt?.toIso8601String(),
      'first_accessed_at': firstAccessedAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
