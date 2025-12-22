import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ========== CRITICAL INIT ONLY (blocking) ==========
  // Hanya yang benar-benar diperlukan sebelum app jalan

  // Set orientations (non-blocking, very fast)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI (non-blocking, very fast)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load env & init Hive (required before app)
  await Future.wait([
    dotenv.load(fileName: 'assets/.env'),
    Hive.initFlutter(),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  // ========== RUN APP IMMEDIATELY ==========
  // Tampilkan splash screen dulu, init sisanya di background
  runApp(const MecaLearningApp());
}
