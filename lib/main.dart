// ===================================================================
// Thai Herbal GACP Platform v3.0 - Complete Flutter Implementation
// © 2024 Predictive AI Solution Co., Ltd.
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection_container.dart';
import 'core/security/security_service.dart';
import 'features/knowledge_graph/data/knowledge_graph_service.dart';
import 'features/historical_data/data/historical_data_service.dart';
import 'features/ai_reasoning/data/reasoning_engine.dart';
import 'features/continuous_learning/data/learning_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local database
  await Hive.initFlutter();
  
  // Setup dependency injection
  await setupDependencyInjection();
  
  // Initialize security and compliance
  final securityService = GetIt.instance<SecurityService>();
  await securityService.ensureCompliance();
  
  // Initialize Knowledge Graph Engine
  final knowledgeGraph = GetIt.instance<KnowledgeGraphService>();
  await knowledgeGraph.initialize();
  
  // Initialize Historical Data Service
  final historicalData = GetIt.instance<HistoricalDataService>();
  await historicalData.loadHistoricalData();
  
  // Initialize Enhanced AI Reasoning
  final reasoningEngine = GetIt.instance<ReasoningEngine>();
  await reasoningEngine.initialize();
  
  // Start Continuous Learning System
  final learningService = GetIt.instance<ContinuousLearningService>();
  learningService.startLearningCycle();
  
  runApp(const ThaiHerbalGACPApp());
}

class ThaiHerbalGACPApp extends StatelessWidget {
  const ThaiHerbalGACPApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => GetIt.instance<CertificationBloc>()),
            BlocProvider(create: (context) => GetIt.instance<TrackingBloc>()),
            BlocProvider(create: (context) => GetIt.instance<KnowledgeBloc>()),
            BlocProvider(create: (context) => GetIt.instance<DashboardBloc>()),
          ],
          child: MaterialApp(
            title: 'Thai Herbal GACP Platform',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.green,
              fontFamily: 'Kanit',
              visualDensity: VisualDensity.adaptivePlatformDensity,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),
            home: const MainNavigationPage(),
            routes: {
              '/certification': (context) => const GACPCertificationPage(),
              '/tracking': (context) => const TrackAndTracePage(),
              '/knowledge': (context) => const KnowledgeGraphPage(),
              '/dashboard': (context) => const DashboardPage(),
            },
          ),
        );
      },
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const DashboardPage(),
    const GACPCertificationPage(),
    const TrackAndTracePage(),
    const KnowledgeGraphPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'แดชบอร์ด',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: 'ขอใบรับรอง',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'ติดตาม',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'ความรู้',
          ),
        ],
      ),
    );
  }
}
