// ===================================================================
// Thai Herbal GACP Platform v3.0 - App Configuration
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/utils/logger.dart';
import 'core/utils/connectivity_service.dart';
import 'core/utils/notification_service.dart';

// Features
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/gacp_certification/presentation/bloc/gacp_bloc.dart';
import 'features/track_and_trace/presentation/bloc/tracking_bloc.dart';
import 'features/knowledge_graph/presentation/bloc/knowledge_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

// Widgets
import 'widgets/common/error_boundary.dart';
import 'widgets/common/loading_overlay.dart';
import 'widgets/common/connectivity_banner.dart';

// ===================================================================
// Main App Widget
// ===================================================================

class ThaiHerbalGACPApp extends StatefulWidget {
  const ThaiHerbalGACPApp({super.key});

  @override
  State<ThaiHerbalGACPApp> createState() => _ThaiHerbalGACPAppState();
}

class _ThaiHerbalGACPAppState extends State<ThaiHerbalGACPApp> 
    with WidgetsBindingObserver {
  
  late final GoRouter _router;
  late final ConnectivityService _connectivityService;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAppLifecycleObserver();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.dispose();
    super.dispose();
  }

  // ===================================================================
  // Initialization
  // ===================================================================

  void _initializeServices() {
    AppLogger.info('🎯 Initializing app services...');
    
    // Initialize router
    _router = di.sl<AppRouter>().router;
    
    // Initialize connectivity service
    _connectivityService = di.sl<ConnectivityService>();
    
    // Initialize notification service
    _notificationService = di.sl<NotificationService>();
    _notificationService.initialize();
    
    AppLogger.info('✅ App services initialized');
  }

  void _setupAppLifecycleObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ===================================================================
  // App Lifecycle
  // ===================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    AppLogger.info('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  void _handleAppResumed() {
    AppLogger.info('📱 App resumed');
    // Refresh authentication status
    di.sl<AuthBloc>().add(const AuthCheckRequested());
    // Check for app updates
    _checkForUpdates();
  }

  void _handleAppPaused() {
    AppLogger.info('⏸️ App paused');
    // Save app state
    _saveAppState();
  }

  void _handleAppDetached() {
    AppLogger.info('🔌 App detached');
    // Clean up resources
    _cleanupResources();
  }

  void _handleAppInactive() {
    AppLogger.info('💤 App inactive');
  }

  void _handleAppHidden() {
    AppLogger.info('🙈 App hidden');
  }

  // ===================================================================
  // App State Management
  // ===================================================================

  void _saveAppState() {
    // Save current state to local storage
    // This could include current route, form data, etc.
  }

  void _cleanupResources() {
    // Clean up any resources that should be released when app is detached
  }

  void _checkForUpdates() {
    // Check for app updates and notify user if available
  }

  // ===================================================================
  // Build Method
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MultiBlocProvider(
        providers: _buildBlocProviders(),
        child: BlocListener<AuthBloc, AuthState>(
          listener: _handleAuthStateChanges,
          child: MaterialApp.router(
            // ===================================================================
            // App Configuration
            // ===================================================================
            title: AppConstants.appName,
            debugShowCheckedModeBanner: AppConstants.showDebugBanner,
            
            // ===================================================================
            // Localization
            // ===================================================================
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            
            // ===================================================================
            // Theme Configuration
            // ===================================================================
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(),
            
            // ===================================================================
            // Navigation
            // ===================================================================
            routerConfig: _router,
            
            // ===================================================================
            // Global Builders
            // ===================================================================
            builder: (context, child) {
              return _buildAppWrapper(context, child);
            },
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // BLoC Providers
  // ===================================================================

  List<BlocProvider> _buildBlocProviders() {
    return [
      // Authentication BLoC
      BlocProvider<AuthBloc>(
        create: (context) => di.sl<AuthBloc>()
          ..add(const AuthCheckRequested()),
      ),
      
      // Dashboard BLoC
      BlocProvider<DashboardBloc>(
        create: (context) => di.sl<DashboardBloc>(),
      ),
      
      // GACP Certification BLoC
      BlocProvider<GacpBloc>(
        create: (context) => di.sl<GacpBloc>(),
      ),
      
      // Tracking BLoC
      BlocProvider<TrackingBloc>(
        create: (context) => di.sl<TrackingBloc>(),
      ),
      
      // Knowledge Graph BLoC
      BlocProvider<KnowledgeBloc>(
        create: (context) => di.sl<KnowledgeBloc>(),
      ),
      
      // Profile BLoC
      BlocProvider<ProfileBloc>(
        create: (context) => di.sl<ProfileBloc>(),
      ),
    ];
  }

  // ===================================================================
  // State Listeners
  // ===================================================================

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthUnauthenticated) {
      // Clear sensitive data when user logs out
      _clearSensitiveData();
    } else if (state is AuthAuthenticated) {
      // Initialize user-specific data
      _initializeUserData(state.user);
    }
  }

  void _clearSensitiveData() {
    // Clear sensitive data from local storage
    AppLogger.info('🧹 Clearing sensitive data');
  }

  void _initializeUserData(dynamic user) {
    // Initialize user-specific data and preferences
    AppLogger.info('👤 Initializing user data for: ${user.name}');
  }

  // ===================================================================
  // App Wrapper Builder
  // ===================================================================

  Widget _buildAppWrapper(BuildContext context, Widget? child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      child: Stack(
        children: [
          // Main app content
          child ?? const SizedBox.shrink(),
          
          // Connectivity banner
          const ConnectivityBanner(),
          
          // Global loading overlay
          const LoadingOverlay(),
          
          // Debug overlay (development only)
          if (AppConstants.isDevelopment) _buildDebugOverlay(),
        ],
      ),
    );
  }

  // ===================================================================
  // Theme Management
  // ===================================================================

  ThemeMode _getThemeMode() {
    // Get theme preference from local storage or system
    // For now, return system default
    return ThemeMode.system;
  }

  // ===================================================================
  // Debug Overlay
  // ===================================================================

  Widget _buildDebugOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'v${AppConstants.appVersion}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.sp,
              ),
            ),
            Text(
              AppConstants.buildMode,
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// Global Error Widget
// ===================================================================

class GlobalErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const GlobalErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.r,
                  color: Colors.red,
                ),
                SizedBox(height: 16.h),
                Text(
                  'เกิดข้อผิดพลาด',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// App Configuration Extensions
// ===================================================================

extension AppConfigurationExtension on BuildContext {
  /// Get current theme data
  ThemeData get theme => Theme.of(this);
  
  /// Get current color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Check if dark mode is enabled
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
  
  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;
}
