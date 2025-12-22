import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/services/supabase_service.dart';
import 'core/services/gdrive_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/activity_log_service.dart';
import 'core/services/push_notification_service.dart';

class MecaLearningApp extends StatelessWidget {
  const MecaLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meca Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

/// Splash Screen dengan background initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Memulai...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // ========== STAGE 1: Core Services (Parallel) ==========
      _updateStatus('Menghubungkan ke server...');

      await Future.wait([
        SupabaseService.initialize(),
        initializeDateFormatting('id_ID', null),
      ]);

      // ========== STAGE 2: Auth Check ==========
      _updateStatus('Memeriksa sesi...');
      final isLoggedIn = await AuthService().initialize();

      // ========== STAGE 3: Secondary Services (Parallel, non-blocking) ==========
      if (isLoggedIn) {
        _updateStatus('Mempersiapkan aplikasi...');

        // Run in parallel, don't wait - these are non-critical
        _initSecondaryServices();
      }

      // ========== NAVIGATE ==========
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          isLoggedIn ? AppRoutes.home : AppRoutes.login,
        );
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  /// Initialize secondary services in background (non-blocking)
  void _initSecondaryServices() {
    // GDrive - lazy init, only when needed
    GDriveService().initialize().catchError((e) {
      debugPrint('GDrive init error (non-fatal): $e');
    });

    // Activity Log
    ActivityLogService().initialize().catchError((e) {
      debugPrint('ActivityLog init error (non-fatal): $e');
    });

    // Push Notifications
    PushNotificationService().initialize().catchError((e) {
      debugPrint('Push notification init error (non-fatal): $e');
    });
  }

  void _updateStatus(String status) {
    if (mounted) {
      setState(() => _status = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              const Text(
                'Meca Learning',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Industrial Training Platform',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),

              // Loading or Error
              if (_hasError) ...[
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Gagal memuat aplikasi',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = null;
                    });
                    _initializeApp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ] else ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
