import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Google Drive Folders
  static String get gdriveFolderModules =>
      dotenv.env['GDRIVE_FOLDER_MODULES'] ?? '';
  static String get gdriveFolderAnimations =>
      dotenv.env['GDRIVE_FOLDER_ANIMATIONS'] ?? '';
  static String get gdriveFolderMecaAid =>
      dotenv.env['GDRIVE_FOLDER_MECA_AID'] ?? '';
  static String get gdriveFolderErrorImages =>
      dotenv.env['GDRIVE_FOLDER_ERROR_IMAGES'] ?? '';

  // App Info
  static String get appName => dotenv.env['APP_NAME'] ?? 'Meca Learning';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  // Default Password
  static const String defaultPassword = 'asto2025';

  // Session
  static const int sessionDurationDays = 30;
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';

  // Activity Types
  static const String activityLogin = 'login';
  static const String activityLogout = 'logout';
  static const String activityViewModule = 'view_module';
  static const String activityViewAnimation = 'view_animation';
  static const String activityViewMecaAid = 'view_meca_aid';
  static const String activityStartQuiz = 'start_quiz';
  static const String activitySubmitAnswer = 'submit_answer';
  static const String activityCompleteQuiz = 'complete_quiz';
  static const String activityViewErrorCode = 'view_error_code';
  static const String activitySearch = 'search';
  static const String activityNavigate = 'navigate';
  static const String activityClickButton = 'click_button';

  // Resource Types
  static const String resourceModule = 'module';
  static const String resourceAnimation = 'animation';
  static const String resourceMecaAid = 'meca_aid';
  static const String resourceErrorCode = 'error_code';
  static const String resourceQuestion = 'question';
  static const String resourceScreen = 'screen';

  // Categories
  static const String categoryModule = 'module';
  static const String categoryAnimation = 'animation';
  static const String categoryMecaAid = 'meca_aid';

  // Severity Levels
  static const String severityLow = 'low';
  static const String severityMedium = 'medium';
  static const String severityHigh = 'high';
  static const String severityCritical = 'critical';
}
