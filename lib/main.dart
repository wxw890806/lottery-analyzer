import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'providers/app_provider.dart';
import 'providers/lottery_provider.dart';
import 'providers/analysis_provider.dart';
import 'providers/prediction_provider.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 初始化数据库
  await DatabaseService.instance.init();
  
  runApp(const LotteryAnalyzerApp());
}

class LotteryAnalyzerApp extends StatelessWidget {
  const LotteryAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => LotteryProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: '彩票规律分析器',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
