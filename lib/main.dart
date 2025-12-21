import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';
import 'core/services/gdrive_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/activity_log_service.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ FIX WAJIB UNTUK WEBVIEW ANDROID

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment variables
  await dotenv.load(fileName: 'assets/.env');

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Google Drive service
  await GDriveService().initialize();

  // Initialize Activity Log service
  await ActivityLogService().initialize();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Check if user is already logged in
  final isLoggedIn = await AuthService().initialize();

  // Initialize Push Notifications (after checking login)
  if (isLoggedIn) {
    await PushNotificationService().initialize();
  }

  runApp(MecaLearningApp(isLoggedIn: isLoggedIn));
}
