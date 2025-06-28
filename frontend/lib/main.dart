// ===================================================================
// Thai Herbal GACP Platform v3.0 - Main Entry Point
// ===================================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/utils/logger.dart';
import 'core/utils/error_handler.dart';
import 'core/utils/device_utils.dart';
import 'core/database/hive_service.dart';
import 'core/security/security_service.dart';
import 'firebase_options.dart';

// ===================================================================
// Global Error Handler
// ===================================================================

/// Handle background Firebase messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('Background message received: ${message.messageId}');
}

/// Global error handler for uncaught exceptions
void _handleUncaughtError(Object error, StackTrace stackTrace) {
  AppLogger.error('Uncaught error: $error', stackTrace);
  
  // Report to Crashlytics in production
  if (AppConstants.isProduction) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  
  // Handle specific error types
  ErrorHandler.handleGlobalError(error, stackTrace);
}

// ===================================================================
// Main Function
// ===================================================================

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _handleUncaughtError(details.exception, details.stack ?? StackTrace.current);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    _handleUncaughtError(error, stack);
    return true;
  };
  
  // Run app with error boundary
  runZonedGuarded(
    () async {
      await _initializeApp();
    },
    _handleUncaughtError,
  );
}

// ===================================================================
// App Initialization
// ===================================================================

Future<void> _initializeApp() async {
  try {
    AppLogger.info('🚀 Initializing Thai Herbal GACP Platform v${AppConstants.appVersion}');
    
    // 1. Load Environment Configuration
    await _loadEnvironmentConfig();
    
    // 2. Initialize Core Services
    await _initializeCoreServices();
    
    // 3. Initialize Firebase
    await _initializeFirebase();
    
    // 4. Initialize Local Database
    await _initializeLocalDatabase();
    
    // 5. Initialize Security
    await _initializeSecurity();
    
    // 6. Initialize Dependency Injection
    await _initializeDependencyInjection();
    
    // 7. Configure System UI
    _configureSystemUI();
    
    // 8. Initialize Localization
    await _initializeLocalization();
    
    // 9. Run Application
    _runApplication();
    
    AppLogger.info('✅ App initialization completed successfully');
    
  } catch (error, stackTrace) {
    AppLogger.error('❌ App initialization failed: $error', stackTrace);
    _handleInitializationError(error, stackTrace);
  }
}

// ===================================================================
// Initialization Steps
// ===================================================================

/// Load environment configuration
Future<void> _loadEnvironmentConfig() async {
  try {
    AppLogger.info('📋 Loading environment configuration...');
    
    // Load .env file based on build mode
    String envFile = '.env';
    if (AppConstants.isDevelopment) {
      envFile = '.env.development';
    } else if (AppConstants.isStaging) {
      envFile = '.env.staging';
    } else if (AppConstants.isProduction) {
      envFile = '.env.production';
    }
    
    await dotenv.load(fileName: envFile);
    AppLogger.info('✅ Environment configuration loaded from $envFile');
    
  } catch (error) {
    AppLogger.warning('⚠️ Could not load environment file, using defaults');
  }
}

/// Initialize core services
Future<void> _initializeCoreServices() async {
  AppLogger.info('🛠️ Initializing core services...');
  
  // Initialize device utilities
  await DeviceUtils.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  AppLogger.info('✅ Core services initialized');
}

/// Initialize Firebase services
Future<void> _initializeFirebase() async {
  try {
    AppLogger.info('🔥 Initializing Firebase...');
    
    // Initialize Firebase Core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Crashlytics
    if (AppConstants.isProduction) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      
      // Set user identifier for crash reports
      await FirebaseCrashlytics.instance.setUserIdentifier(
        DeviceUtils.deviceId ?? 'unknown',
      );
    }
    
    // Initialize Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request notification permissions
    await _requestNotificationPermissions();
    
    AppLogger.info('✅ Firebase initialized successfully');
    
  } catch (error, stackTrace) {
    AppLogger.error('❌ Firebase initialization failed: $error', stackTrace);
    // Continue without Firebase in development
    if (!AppConstants.isDevelopment) {
      rethrow;
    }
  }
}

/// Request notification permissions
Future<void> _requestNotificationPermissions() async {
  final messaging = FirebaseMessaging.instance;
  
  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  AppLogger.info('Notification permission: ${settings.authorizationStatus}');
}

/// Initialize local database (Hive)
Future<void> _initializeLocalDatabase() async {
  try {
    AppLogger.info('🗄️ Initializing local database...');
    
    // Initialize Hive
    await Hive.initFlutter();
    
    // Initialize Hive service
    await HiveService.initialize();
    
    AppLogger.info('✅ Local database initialized');
    
  } catch (error, stackTrace) {
    AppLogger.error('❌ Local database initialization failed: $error', stackTrace);
    rethrow;
  }
}

/// Initialize security services
Future<void> _initializeSecurity() async {
  try {
    AppLogger.info('🔒 Initializing security services...');
    
    // Initialize security service
    await SecurityService.initialize();
    
    // Check for rooted/jailbroken devices in production
    if (AppConstants.isProduction) {
      final isCompromised = await SecurityService.isDeviceCompromised();
      if (isCompromised) {
        AppLogger.warning('⚠️ Device security compromised detected');
        // Handle compromised device (show warning, limit functionality, etc.)
      }
    }
    
    AppLogger.info('✅ Security services initialized');
    
  } catch (error, stackTrace) {
    AppLogger.error('❌ Security initialization failed: $error', stackTrace);
    // Continue without advanced security features
  }
}

/// Initialize dependency injection
Future<void> _initializeDependencyInjection() async {
  try {
    AppLogger.info('💉 Initializing dependency injection...');
    
    // Initialize service locator
    await di.init();
    
    AppLogger.info('✅ Dependency injection initialized');
    
  } catch (error, stackTrace) {
    AppLogger.error('❌ Dependency injection failed: $error', stackTrace);
    rethrow;
  }
}

/// Configure system UI
void _configureSystemUI() {
  AppLogger.info('🎨 Configuring system UI...');
  
  // Set system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Hide system overlays if needed
  if (AppConstants.hideSystemUI) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
  AppLogger.info('✅ System UI configured');
}

/// Initialize localization
Future<void> _initializeLocalization() async {
  try {
    AppLogger.info('🌐 Initializing localization...');
    
    // Initialize EasyLocalization
    await EasyLocalization.ensureInitialized();
    
    AppLogger.info('✅ Localization initialized');
    
  } catch (error, stackTrace) {
    AppLogger.error('❌ Localization initialization failed: $error', stackTrace);
    // Continue with default locale
  }
}

/// Run the Flutter application
void _runApplication() {
  AppLogger.info('🎯 Starting Flutter application...');
  
  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.translationsPath,
      fallbackLocale: AppConstants.fallbackLocale,
      startLocale: AppConstants.defaultLocale,
      useOnlyLangCode: true,
      child: const MyApp(),
    ),
  );
}

// ===================================================================
// Error Handling
// ===================================================================

/// Handle initialization errors
void _handleInitializationError(Object error, StackTrace stackTrace) {
  AppLogger.error('Critical initialization error: $error', stackTrace);
  
  // Show critical error dialog
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'เกิดข้อผิดพลาดในการเริ่มต้นแอป',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'โปรดลองเปิดแอปใหม่อีกครั้ง',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else {
                    exit(0);
                  }
                },
                child: const Text('ปิดแอป'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ===================================================================
// App Widget
// ===================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 13 mini reference
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            // Global BLoCs will be provided here
          ],
          child: const ThaiHerbalGACPApp(),
        );
      },
    );
  }
}
