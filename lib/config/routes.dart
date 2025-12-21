import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/modules/presentation/modules_screen.dart';
import '../features/modules/presentation/module_detail_screen.dart';
import '../features/animations/presentation/animations_screen.dart';
import '../features/animations/presentation/animation_player_screen.dart';
import '../features/meca_aid/presentation/meca_aid_screen.dart';
import '../features/meca_aid/presentation/meca_aid_detail_screen.dart';
import '../features/meca_aid/presentation/quiz_screen.dart';
import '../features/error_codes/presentation/error_codes_screen.dart';
import '../features/error_codes/presentation/error_code_detail_screen.dart';
import '../features/activity_log/presentation/activity_log_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../shared/models/module_model.dart';
import '../shared/models/error_code_model.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String modules = '/modules';
  static const String moduleDetail = '/modules/detail';
  static const String animations = '/animations';
  static const String animationPlayer = '/animations/player';
  static const String mecaAid = '/meca-aid';
  static const String mecaAidDetail = '/meca-aid/detail';
  static const String quiz = '/meca-aid/quiz';
  static const String errorCodes = '/error-codes';
  static const String errorCodeDetail = '/error-codes/detail';
  static const String activityLog = '/activity-log';
  static const String adminDashboard = '/admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen(), settings);

      case home:
        return _buildRoute(const HomeScreen(), settings);

      case modules:
        return _buildRoute(const ModulesScreen(), settings);

      case moduleDetail:
        final module = settings.arguments as ModuleModel;
        return _buildRoute(ModuleDetailScreen(module: module), settings);

      case animations:
        return _buildRoute(const AnimationsScreen(), settings);

      case animationPlayer:
        final module = settings.arguments as ModuleModel;
        return _buildRoute(AnimationPlayerScreen(module: module), settings);

      case mecaAid:
        return _buildRoute(const MecaAidScreen(), settings);

      case mecaAidDetail:
        final module = settings.arguments as ModuleModel;
        return _buildRoute(MecaAidDetailScreen(module: module), settings);

      case quiz:
        final module = settings.arguments as ModuleModel;
        return _buildRoute(QuizScreen(module: module), settings);

      case errorCodes:
        return _buildRoute(const ErrorCodesScreen(), settings);

      case errorCodeDetail:
        final errorCode = settings.arguments as ErrorCodeModel;
        return _buildRoute(
            ErrorCodeDetailScreen(errorCode: errorCode), settings);

      case activityLog:
        return _buildRoute(const ActivityLogScreen(), settings);

      case adminDashboard:
        return _buildRoute(const AdminDashboardScreen(), settings);

      default:
        return _buildRoute(const LoginScreen(), settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
